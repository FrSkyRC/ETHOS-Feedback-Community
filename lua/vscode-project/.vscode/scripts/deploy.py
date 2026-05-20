import os
import shutil
import argparse
import json
import subprocess
try:
    import subprocess_conout
except Exception:
    subprocess_conout = None
import sys
import stat
try:
    from tqdm import tqdm
except Exception:
    class _NoopTqdm:
        def __init__(self, total=None, desc=None, **kwargs):
            self.total = total
            self.desc = desc

        def update(self, n=1):
            return None

        def close(self):
            return None

    def tqdm(*args, **kwargs):
        return _NoopTqdm(**kwargs)
import re
import shlex
import time
import atexit, signal, tempfile
import platform
from hashlib import md5
from glob import glob
from pathlib import Path


# === Optional direct radio control (no Ethos Suite needed) =====================
# We can switch the radio USB mode and discover mount points by talking directly
# to the device (same USB HID interface Ethos Suite uses) and scanning for *.cpuid
# markers. If dependencies are missing, we gracefully fall back to a pure drive scan.
CONNECT_MODULE_PATH = os.path.join(os.path.dirname(__file__), "connect.py")
_connect_mod = None

def _load_connect_module():
    global _connect_mod
    if _connect_mod is not None:
        return _connect_mod
    try:
        import importlib.util
        spec = importlib.util.spec_from_file_location("ethos_template_connect", CONNECT_MODULE_PATH)
        if spec and spec.loader:
            mod = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(mod)  # type: ignore
            _connect_mod = mod
            return _connect_mod
    except BaseException as e:
        print(f"[CONNECT] connect.py unavailable ({type(e).__name__}: {e}); using drive-scan fallback.")
    _connect_mod = False
    return _connect_mod

def _connect_usb_debug(action: str):
    """Start/stop USB debug (serial) using connect.py if available."""
    mod = _load_connect_module()
    if not mod:
        return False
    ri = None
    try:
        ri = mod.RadioInterface()
        if action == 'start':
            print("[CONNECT] Starting USB debug (serial)…")
            ri.start_usb_debug()
        elif action == 'stop':
            print("[CONNECT] Stopping USB debug (serial)…")
            ri.stop_usb_debug()
        else:
            raise ValueError(f"Unknown action: {action}")
        return True
    except BaseException as e:
        err = str(e)
        # On some macOS setups the HID interface is visible but not openable;
        # deploy can still proceed using mounted-volume fallback.
        if "No Ethos compatible HID device found" in err and "vendor present" in err:
            print(
                f"[CONNECT] USB debug {action} unavailable (HID seen but not openable in this session); "
                "continuing with mounted-volume workflow."
            )
        else:
            print(f"[CONNECT] USB debug {action} failed ({type(e).__name__}: {e})")
        return False
    finally:
        try:
            if ri is not None:
                ri.close()
        except Exception:
            pass

def _connect_find_scripts_dir():
    """Return mounted scripts dir using connect.py drive markers, or None."""
    mod = _load_connect_module()
    if not mod:
        return None
    ri = None
    try:
        ri = mod.RadioInterface()
        ri.scan_for_drives()
        # Prefer sdcard/radio volumes if present; Ethos maps SCRIPTS to the mounted media root + /scripts
        for key in ('sdcard', 'radio', 'flash'):
            root = ri.drives.get(key)
            if root and os.path.isdir(os.path.join(root, 'scripts')):
                return os.path.normpath(os.path.join(root, 'scripts'))
    except BaseException as e:
        print(f"[CONNECT] Drive scan failed ({type(e).__name__}: {e})")
    finally:
        try:
            if ri is not None:
                ri.close()
        except Exception:
            pass
    return None

MIN_ETHOSSUITE_VERSION = "1.7.0"

SERIAL_PIDFILE = os.path.join(tempfile.gettempdir(), "deploy-serial.pid")
DEPLOY_TO_RADIO = False  # flag to control radio-only behavior
DEPLOY_STAGE = True     # whether to stage locally before copying to radio
THROTTLE_EXTS = None  # unused when throttling all copies
THROTTLE_MIN_BYTES = 0  # unused when throttling all copies
THROTTLE_CHUNK = 32 * 1024          # 32 KiB
THROTTLE_PAUSE_EVERY = 64 * 1024    # pause+fsync every 64 KiB written
THROTTLE_PAUSE_S = 0.1              # 100 ms
COPY_SETTLE_S = float(os.environ.get("DEPLOY_COPY_SETTLE_S", "0.10"))  # 100 ms

# --- staging (run steps locally then copy to radio) --------------------------
STAGING_ENABLED = True  # can be disabled via --no-stage or env DEPLOY_STAGE=0
STAGING_KEEP = False    # set env DEPLOY_STAGE_KEEP=1 to keep staging folder for debugging
_STAGE_ROOTS = []

def _staging_is_enabled(args=None):
    # CLI arg wins, then env var, then default
    if args is not None and getattr(args, 'no_stage', False):
        return False
    env = os.environ.get('DEPLOY_STAGE', '').strip().lower()
    if env in ('0', 'false', 'no', 'off'):
        return False
    return STAGING_ENABLED

def _stage_mkdir(prefix='ethos-deploy-stage-'):
    root = tempfile.mkdtemp(prefix=prefix)
    _STAGE_ROOTS.append(root)
    return root

def _cleanup_stage_roots():
    keep = os.environ.get('DEPLOY_STAGE_KEEP', '').strip().lower() in ('1','true','yes','on')
    if keep or STAGING_KEEP:
        for r in _STAGE_ROOTS:
            print(f"[STAGE] Keeping staging folder: {r}")
        return
    for r in _STAGE_ROOTS:
        try:
            shutil.rmtree(r, onerror=on_rm_error)
        except Exception:
            pass

atexit.register(_cleanup_stage_roots)

# --- single-instance lock helpers --------------------------------------------
LOCK_DEFAULT_NAME = "deploy.single.lock"
if os.name == "nt":
    import msvcrt
else:
    import fcntl

def _lock_file(fd):
    if os.name == "nt":
        msvcrt.locking(fd.fileno(), msvcrt.LK_NBLCK, 1)
    else:
        fcntl.flock(fd.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)

def _unlock_file(fd):
    try:
        if os.name == "nt":
            fd.seek(0)
            msvcrt.locking(fd.fileno(), msvcrt.LK_UNLCK, 1)
        else:
            fcntl.flock(fd.fileno(), fcntl.LOCK_UN)
    except OSError:
        pass

def _pid_is_running(pid: int) -> bool:
    if pid <= 0:
        return False
    try:
        os.kill(pid, 0)
        return True
    except OSError:
        return False

class SingleInstance:
    """OS-level file lock + PID metadata to ensure only one deploy.py instance."""
    def __init__(self, name: str = LOCK_DEFAULT_NAME, force: bool = False):
        self.lock_path = os.path.join(tempfile.gettempdir(), name)
        self.force = force
        self.fd = None
        self._acquired = False

    def acquire(self):
        self.fd = open(self.lock_path, "a+")
        self.fd.seek(0)
        try:
            _lock_file(self.fd)
            self._acquired = True
        except OSError:
            # Check if the current holder is stale
            self.fd.seek(0)
            holder_pid = -1
            try:
                import json as _json
                meta = (self.fd.read() or "").strip()
                data = _json.loads(meta) if meta else {}
                holder_pid = int(data.get("pid", -1))
            except Exception:
                pass
            if holder_pid > 0 and not _pid_is_running(holder_pid):
                if not self.force:
                    raise RuntimeError(
                        f"Another deploy appears to be running (stale lock from PID {holder_pid}). "
                        f"Re-run with --force to take over. Lock: {self.lock_path}"
                    )
                time.sleep(0.2)
                _lock_file(self.fd)
                self._acquired = True
            else:
                raise RuntimeError(
                    f"Another deploy is already running (PID {holder_pid if holder_pid>0 else 'unknown'})."
                )
        # record metadata
        try:
            self.fd.seek(0); self.fd.truncate(0)
            import json as _json
            _json.dump({"pid": os.getpid(), "time": time.time(), "host": platform.node()}, self.fd)
            self.fd.flush(); os.fsync(self.fd.fileno())
        except Exception:
            pass
        atexit.register(self.release)
        for sig in (signal.SIGINT, signal.SIGTERM):
            try:
                signal.signal(sig, self._signal_and_release)
            except Exception:
                pass

    def _signal_and_release(self, signum, frame):
        self.release()
        signal.signal(signum, signal.SIG_DFL)
        os.kill(os.getpid(), signum)

    def release(self):
        if self._acquired and self.fd:
            try:
                self.fd.seek(0); self.fd.truncate(0); self.fd.flush()
                _unlock_file(self.fd)
            finally:
                try: self.fd.close()
                except Exception: pass
                try: os.remove(self.lock_path)
                except Exception: pass
            self._acquired = False

def _lock_path_for_config(config_path: str) -> str:
    """Compute the exact lock file path used for this project/config."""
    proj_key = md5(os.path.abspath(config_path).encode("utf-8")).hexdigest()[:8]
    lock_name = f"deploy-{proj_key}.lock"
    return os.path.join(tempfile.gettempdir(), lock_name)

def parse_version(v: str):
    m = re.search(r'(\d+)\.(\d+)\.(\d+)', v or "")
    if not m:
        raise ValueError(f"Invalid version: {v}")
    return tuple(map(int, m.groups()))

def check_ethossuite_version(ethossuite_bin, min_version=MIN_ETHOSSUITE_VERSION):
    if not ethossuite_bin:
        # Ethos Suite is optional; we can operate without it using connect.py + drive scans.
        print("[ETHOS] Ethos Suite not configured; continuing without it.")
        return True
    try:
        res = subprocess.run(
            [ethossuite_bin, "--version"],
            text=True,
            capture_output=True,
            timeout=10
        )
    except FileNotFoundError:
        print(f"[ERROR] Ethos Suite not found at: {ethossuite_bin}")
        return False
    except subprocess.TimeoutExpired:
        print("[ERROR] Ethos Suite --version timed out.")
        return False

    if res.returncode != 0:
        print(f"[ERROR] Ethos Suite exited with code {res.returncode}")
        return False

    lines = [l.strip() for l in (res.stdout or "").splitlines() if l.strip()]
    version_re = re.compile(r'^\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?$')
    version = next((l for l in lines if version_re.match(l)), None)

    if not version:
        print(f"[ERROR] Could not parse Ethos Suite version from output:\n{res.stdout}")
        return False

    if parse_version(version) < parse_version(min_version):
        print(f"[ERROR] Ethos Suite version {version} is too old (need >= {min_version})")
        return False

    print(f"[ETHOS] Detected Ethos Suite version {version} ✓")
    return True


def file_md5(path, chunk=1024 * 1024):
    import hashlib
    h = hashlib.md5()
    with open(path, 'rb', buffering=0) as f:
        while True:
            b = f.read(chunk)
            if not b:
                break
            h.update(b)
    return h.hexdigest()

def _kill_previous_tail_if_any():
    try:
        with open(SERIAL_PIDFILE, "r") as f:
            old = int((f.read() or "0").strip())
    except Exception:
        return
    if old and old != os.getpid():
        try:
            if os.name == "nt":
                subprocess.run(["taskkill", "/PID", str(old), "/T", "/F"],
                               stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            else:
                os.kill(old, signal.SIGTERM)
                time.sleep(0.3)
                try: os.kill(old, signal.SIGKILL)
                except Exception: pass
        except Exception:
            pass
    try: os.remove(SERIAL_PIDFILE)
    except Exception: pass

def _record_tail_pid_and_cleanup():
    try:
        with open(SERIAL_PIDFILE, "w") as f:
            f.write(str(os.getpid()))
    except Exception:
        pass
    atexit.register(lambda: os.path.exists(SERIAL_PIDFILE) and os.remove(SERIAL_PIDFILE))


def throttled_copyfile(src, dst):
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    written_since_pause = 0
    with open(src, 'rb', buffering=0) as fsrc, open(dst, 'wb', buffering=0) as fdst:
        while True:
            chunk = fsrc.read(THROTTLE_CHUNK)
            if not chunk:
                break
            fdst.write(chunk)
            written_since_pause += len(chunk)
            if written_since_pause >= THROTTLE_PAUSE_EVERY:
                fdst.flush()
                try:
                    os.fsync(fdst.fileno())
                except OSError:
                    pass
                time.sleep(THROTTLE_PAUSE_S)
                written_since_pause = 0

        fdst.flush()
        try:
            os.fsync(fdst.fileno())
        except OSError:
            pass

    try:
        shutil.copymode(src, dst)
    except Exception:
        pass
    if COPY_SETTLE_S > 0:
        time.sleep(COPY_SETTLE_S)

def scan_usb_drives_for_radio():
    """
    Strong fallback: scan mounted drives for:
      - radio.bin (file)
      - scripts/  (directory)
    Returns the scripts directory path or None.
    """
    import string
    candidates = []

    print("[ETHOS] Performing fallback USB drive scan for radio…")

    if os.name == "nt":
        for letter in string.ascii_uppercase:
            root = f"{letter}:\\"
            try:
                if (
                    os.path.isdir(os.path.join(root, "scripts"))
                ):
                    candidates.append(os.path.normpath(os.path.join(root, "scripts")))
            except Exception:
                pass
    else:
        for base in ("/Volumes", "/media", "/mnt"):
            if not os.path.isdir(base):
                continue
            for entry in os.listdir(base):
                root = os.path.join(base, entry)
                try:
                    if (
                        os.path.isfile(os.path.join(root, "radio.bin")) and
                        os.path.isdir(os.path.join(root, "scripts"))
                    ):
                        candidates.append(os.path.normpath(os.path.join(root, "scripts")))
                except Exception:
                    pass

    if candidates:
        print(f"[ETHOS] Fallback USB scan found radio at: {candidates[0]}")
        return candidates[0]
    return None



def get_ethos_scripts_dir(ethossuite_bin, retries=1, delay=5):
    """
    Ask Ethos Suite for the SCRIPTS path. Robust against chatty output.
    """
    import re, json

    # Prefer direct connect.py discovery (no Ethos Suite required).
    cp = _connect_find_scripts_dir()
    if cp:
        return cp

    cmd = [ethossuite_bin, "--get-path", "SCRIPTS", "--radio", "auto"]
    path_re = re.compile(r'^(?:[A-Za-z]:\\|\\\\\?\\|//|/)[^\r\n]+$')

    def _clean(line: str) -> str:
        line = (line or "").strip().strip('"').strip("'")
        if not line:
            return ""
        low = line.lower()
        if low.startswith("exit code"):
            return ""
        if low.startswith("new removable disks"):
            return line  # keep for JSON parse
        if line.startswith("{") or line.startswith("["):
            return line
        return line


    last_err = None
    for attempt in range(retries + 1):
        try:
            res = subprocess.run(cmd, text=True, capture_output=True, timeout=20)
            if res.returncode != 0:
                raise subprocess.CalledProcessError(res.returncode, cmd, output=res.stdout, stderr=res.stderr)

            raw = res.stdout or ""
            lines = [_clean(l) for l in raw.splitlines() if l.strip()]
            candidates = [l for l in lines if path_re.match(l)]
            existing = [os.path.normpath(p) for p in candidates if os.path.isdir(os.path.normpath(p))]
            if existing:
                preferred = [p for p in existing if os.path.basename(p).lower() == "scripts"]
                return preferred[0] if preferred else existing[0]
            if candidates:
                preferred = [p for p in candidates if "scripts" in p.lower()]
                return os.path.normpath(preferred[0] if preferred else candidates[0])

            blob_lines = [l for l in lines if l.lower().startswith("new removable disks")]
            if blob_lines:
                blob = blob_lines[-1]
                try:
                    start = blob.index('['); end = blob.rindex(']') + 1
                    arr = json.loads(blob[start:end])
                    choice = None
                    for item in arr:
                        if item.get("radioDisk") == "radio":
                            choice = item; break
                    if not choice and arr:
                        choice = arr[0]
                    if choice:
                        mps = choice.get("mountpoints") or []
                        for mp in mps:
                            p = (mp.get("path") or "").strip()
                            if p:
                                scripts = os.path.normpath(os.path.join(p, "scripts"))
                                return scripts
                except Exception:
                    pass

            # Final fallback: explicit USB scan
            fallback = scan_usb_drives_for_radio()
            if fallback:
                return fallback

            raise RuntimeError("No path-like output from Ethos Suite and no valid radio drive found.")
        except (subprocess.CalledProcessError, FileNotFoundError, subprocess.TimeoutExpired, RuntimeError) as e:
            last_err = e
            if attempt < retries:
                print(f"[ETHOS] Could not get SCRIPTS path (attempt {attempt+1}/{retries+1}). Retrying in {delay}s…")
                time.sleep(delay)
            else:
                raise last_err

            # IMPORTANT: also attempt USB fallback when Ethos Suite fails (non-zero/timeout/etc)
            fb = scan_usb_drives_for_radio()
            if fb:
                return fb



def on_rm_error(func, path, exc_info):
    """Resilient rm error handler."""
    e = exc_info[1]
    if isinstance(e, FileNotFoundError):
        return
    try:
        os.chmod(path, stat.S_IWRITE)
    except FileNotFoundError:
        return

    for i in range(5):
        try:
            func(path)
            return
        except FileNotFoundError:
            return
        except OSError as oe:
            if getattr(oe, "winerror", 0) in (5, 32, 483):
                time.sleep(0.2 * (i + 1))
                continue
            raise


def flush_fs():
    """Attempt to flush filesystem buffers (best-effort)."""
    try:
        if hasattr(os, "sync"):
            os.sync()
    except Exception as e:
        print(f"[WARN] os.sync failed: {e}")


DELETE_BATCH = 1
DELETE_PAUSE_S = 0.10  # 100ms

def throttled_rmtree(root, batch=DELETE_BATCH, pause=DELETE_PAUSE_S):
    if not os.path.exists(root):
        return
    files = []
    for dp, _, fs in os.walk(root):
        for f in fs:
            files.append(os.path.join(dp, f))

    bar = tqdm(total=len(files), desc="Deleting")
    for i, p in enumerate(files, 1):
        try:
            os.chmod(p, stat.S_IWRITE)
        except Exception:
            pass

        attempt = 0
        while True:
            try:
                os.unlink(p)
                break
            except FileNotFoundError:
                break
            except OSError as oe:
                if getattr(oe, "winerror", 0) in (5, 32, 483) and attempt < 5:
                    time.sleep(pause * (attempt + 1))
                    attempt += 1
                    continue
                break

        bar.update(1)
        if i % batch == 0:
            flush_fs()
            time.sleep(pause)

    bar.close()

    for dp, dns, _ in sorted(os.walk(root), key=lambda t: t[0], reverse=True):
        for d in dns:
            try:
                os.rmdir(os.path.join(dp, d))
            except Exception:
                pass
    try:
        os.rmdir(root)
    except Exception:
        pass
    flush_fs()
    time.sleep(pause)


def delete_tree(path):
    if not os.path.isdir(path):
        return
    if DEPLOY_TO_RADIO:
        throttled_rmtree(path)
    else:
        shutil.rmtree(path, onerror=on_rm_error)
        flush_fs()
        time.sleep(DELETE_PAUSE_S)


def safe_full_copy(srcall, out_dir):
    """Safer full-copy for slow FAT32 targets."""
    global pbar
    if os.path.isdir(out_dir):
        old_dir = out_dir + ".old"

        if os.path.isdir(old_dir):
            print("Deleting previous backup…")
            delete_tree(old_dir)
            flush_fs()
            time.sleep(2)

        try:
            print(f"Renaming existing to {os.path.basename(old_dir)}…")
            os.replace(out_dir, old_dir)
        except Exception as e:
            print(f"[WARN] Rename failed ({e}). Falling back to direct delete.")
            print("Deleting files…")
            delete_tree(out_dir)
        flush_fs()
        time.sleep(2)

        if os.path.isdir(old_dir):
            print("Deleting files…")
            delete_tree(old_dir)
            flush_fs()
            time.sleep(2)

    print("Copying files…")
    total = count_files(srcall)
    pbar = tqdm(total=total)
    shutil.copytree(srcall, out_dir, dirs_exist_ok=True, copy_function=copy_verbose)
    pbar.close()


def _needs_copy_with_md5(srcf, dstf, ts_slack=2.0):
    try:
        ss = os.stat(srcf)
    except FileNotFoundError:
        return False
    if not os.path.exists(dstf):
        return True
    try:
        ds = os.stat(dstf)
    except FileNotFoundError:
        return True

    if ss.st_size != ds.st_size:
        return True

    # Fast path: same size and near-identical timestamps are considered unchanged.
    # If timestamps drift (e.g. post-step rewrites), fall back to MD5 before copying.
    if abs(ss.st_mtime - ds.st_mtime) <= ts_slack:
        return False
    try:
        return file_md5(srcf) != file_md5(dstf)
    except Exception:
        return True


def _remove_empty_dirs(root):
    if not os.path.isdir(root):
        return
    for dp, dns, fs in os.walk(root, topdown=False):
        if dns or fs:
            continue
        try:
            os.rmdir(dp)
        except Exception:
            pass


def mirror_copy(src_dir, dst_dir, delete_stale=True, ts_slack=2.0):
    """
    Incremental mirror copy similar to:
      rsync -avh src/ dst/ --delete
    """
    os.makedirs(dst_dir, exist_ok=True)

    src_files = {}
    for r, _, files in os.walk(src_dir):
        for f in files:
            srcf = os.path.join(r, f)
            rel = os.path.relpath(srcf, src_dir)
            src_files[rel] = srcf

    dst_files = {}
    if os.path.isdir(dst_dir):
        for r, _, files in os.walk(dst_dir):
            for f in files:
                dstf = os.path.join(r, f)
                rel = os.path.relpath(dstf, dst_dir)
                dst_files[rel] = dstf

    to_copy = []
    if src_files:
        bar_verify = tqdm(total=len(src_files), desc="Verifying (MD5)")
        for rel, srcf in src_files.items():
            dstf = os.path.join(dst_dir, rel)
            os.makedirs(os.path.dirname(dstf), exist_ok=True)
            if _needs_copy_with_md5(srcf, dstf, ts_slack=ts_slack):
                to_copy.append((rel, srcf, dstf))
            bar_verify.update(1)
        bar_verify.close()

    if to_copy:
        bar_update = tqdm(total=len(to_copy), desc="Updating files")
        for rel, srcf, dstf in to_copy:
            if DEPLOY_TO_RADIO:
                throttled_copyfile(srcf, dstf)
                flush_fs()
                time.sleep(0.05)
            else:
                shutil.copy2(srcf, dstf)
            if not rel.replace(os.sep, "/").endswith("tasks/logger/init.lua"):
                print(f"Copy {rel}")
            bar_update.update(1)
        bar_update.close()

    removed = 0
    if delete_stale and dst_files:
        stale = [rel for rel in dst_files.keys() if rel not in src_files]
        if stale:
            bar_delete = tqdm(total=len(stale), desc="Deleting stale")
            for rel in stale:
                p = os.path.join(dst_dir, rel)
                try:
                    os.remove(p)
                    removed += 1
                except FileNotFoundError:
                    pass
                except Exception as e:
                    print(f"[WARN] Failed to delete stale file {rel}: {e}")
                bar_delete.update(1)
            bar_delete.close()
            _remove_empty_dirs(dst_dir)

    if not to_copy and removed == 0:
        print("Fast deploy: nothing to update.")
    elif removed:
        print(f"Removed {removed} stale file(s).")

# --- config: derive repo root and load deploy.json ----------------------------
ROOT = Path(__file__).resolve().parents[2]

ROOT_CONFIG = ROOT / "deploy.json"
VSCODE_CONFIG = ROOT / ".vscode/deploy.json"

config = {
    "git_src": str(ROOT),
}

cfg_path = None
if ROOT_CONFIG.exists():
    cfg_path = ROOT_CONFIG
elif VSCODE_CONFIG.exists():
    cfg_path = VSCODE_CONFIG
else:
    print("[ERROR] No deploy.json found in git root or .vscode/")
    sys.exit(1)

# NEW: Debug which base config file we are using
print(f"[CONFIG] Using base config file: {cfg_path}")

try:
    with open(cfg_path, "r") as f:
        user_cfg = json.load(f)
    if not isinstance(user_cfg, dict):
        raise ValueError("Config JSON must contain an object at the top level.")
    config.update(user_cfg)
except Exception as e:
    print(f"[ERROR] Failed to load config: {e}")
    sys.exit(1)

if "tgt_name" not in config or not config["tgt_name"]:
    print(f"[ERROR] Missing 'tgt_name' in {cfg_path}. Aborting.")
    sys.exit(1)

CONFIG_PATH = str(cfg_path)

pbar = None

# === Ethos Serial + Serial Tail helpers =======================================

DEFAULT_SERIAL_VID = "0483"
DEFAULT_SERIAL_PID = "5750"
DEFAULT_SERIAL_BAUD = 115200
DEFAULT_SERIAL_RETRIES = 10
DEFAULT_SERIAL_DELAY = 1.0

def ethos_serial(ethossuite_bin, action, radio=None):
    # Ethos Suite is optional. Prefer connect.py HID mode switching when available.
    if not ethossuite_bin:
        ok = _connect_usb_debug(action)
        return (0 if ok else 1), '', ''

    cmd = [ethossuite_bin, "--serial", action, "--radio", "auto"]
    if radio:
        cmd += ["--radio", radio]
    try:
        res = subprocess.run(cmd, text=True, capture_output=True, timeout=20)
        out = (res.stdout or "").strip()
        err = (res.stderr or "").strip()
        if out:
            print(out)
        if err:
            print(err)
        return res.returncode, out, err
    except Exception as e:
        print(f"[ETHOS] --serial {action} failed: {e}")
        # Fallback: direct HID mode switching
        ok = _connect_usb_debug(action)
        if ok:
            return 0, "", ""
        return 1, "", str(e)


def wait_for_scripts_mount(ethossuite_bin=None, attempts=10, delay=2):
    """
    Poll Ethos Suite for the mounted SCRIPTS directory.

    Behaviour:
      - Try Ethos Suite up to `attempts` times.
      - If still not mounted, perform a final USB drive scan fallback.
    Debug:
      - Set DEPLOY_DEBUG_MOUNT=1 to print the returned path / exception each attempt.
    """
    debug_mount = os.environ.get("DEPLOY_DEBUG_MOUNT", "").strip().lower() in ("1", "true", "yes", "on")

    last_err = None
    last_path = None
    recovery_cycle_done = False

    # Give the radio a moment after switching from USB debug to mass-storage.
    if delay > 0:
        time.sleep(min(delay, 2))

    for i in range(attempts):
        # Re-assert mass-storage mode if mount does not appear quickly.
        # Some radios miss the first mode-switch command while USB is re-enumerating.
        if i > 0 and i % 3 == 0:
            try:
                print(f"[ETHOS] Re-requesting mass-storage mode ({i+1}/{attempts})…")
                ethos_serial(ethossuite_bin, 'stop')
            except Exception:
                pass

        # One-time recovery: bounce debug -> storage to force a fresh USB re-enumeration.
        if i >= max(2, attempts // 2) and not recovery_cycle_done:
            try:
                print("[ETHOS] Radio drive still missing; forcing USB mode reinit (debug -> storage)…")
                ethos_serial(ethossuite_bin, 'start')
                time.sleep(1.0)
                ethos_serial(ethossuite_bin, 'stop')
                recovery_cycle_done = True
            except Exception:
                pass

        # First: direct connect.py drive discovery
        path = _connect_find_scripts_dir()
        if path and os.path.isdir(path):
            mounted = os.path.normpath(path)
            print(f"[CONNECT] Radio drive mounted: {mounted}")
            return mounted
        # Second: simple drive scan fallback
        fb = scan_usb_drives_for_radio()
        if fb and os.path.isdir(fb):
            return os.path.normpath(fb)
        # Third: if Ethos Suite is configured, ask it too (legacy)
        if ethossuite_bin:
            try:
                path = get_ethos_scripts_dir(ethossuite_bin, retries=0, delay=delay)
                if path and os.path.isdir(path):
                    mounted = os.path.normpath(path)
                    print(f"[ETHOS] Radio drive mounted: {mounted}")
                    return mounted
            except Exception as e:
                pass
        try:
            last_path = path
            if debug_mount:
                print(f"[ETHOS][DEBUG] get_ethos_scripts_dir -> {path!r}")
            if path and os.path.isdir(path):
                mounted = os.path.normpath(path)
                print(f"[ETHOS] Radio drive mounted: {mounted}")
                return mounted
            raise RuntimeError(f"Ethos returned non-directory path: {path!r}")
        except Exception as e:
            last_err = e
            if debug_mount:
                print(f"[ETHOS][DEBUG] attempt {i+1}/{attempts} failed: {type(e).__name__}: {e}")
            print(f"[ETHOS] Waiting for radio drive ({i+1}/{attempts})…")
            time.sleep(delay)

    # Final fallback: explicit USB scan (only after Ethos Suite polling is exhausted)
    print("[ETHOS] Ethos Suite polling exhausted; attempting USB drive scan fallback…")
    fb = None
    try:
        fb = scan_usb_drives_for_radio()
    except Exception as e:
        if debug_mount:
            print(f"[ETHOS][DEBUG] scan_usb_drives_for_radio crashed: {type(e).__name__}: {e}")

    if fb and os.path.isdir(fb):
        fb = os.path.normpath(fb)
        print(f"[ETHOS] USB scan fallback found radio: {fb}")
        return fb

    raise RuntimeError(f"Radio drive did not mount (last_path={last_path!r}): {last_err}")
def _find_com_port_by_vid_pid(vid_hex, pid_hex):
    try:
        from serial.tools import list_ports
    except Exception as e:
        print("[SERIAL] pyserial not installed. Install with: pip install pyserial")
        return None


def _find_com_port(vid_hex=None, pid_hex=None, name_hint=None, allow_fuzzy_if_no_vidpid=True, prefer_pid_from_hwid=True):
    try:
        from serial.tools import list_ports
    except Exception:
        print("[SERIAL] pyserial not installed. Install with: pip install pyserial")
        return None

    ports = list(list_ports.comports())
    if not ports:
        print("[SERIAL] No serial ports detected.")
        return None

    print("[SERIAL] Detected ports:")
    for p in ports:
        desc = p.description or ''
        iface = getattr(p, 'interface', None) or ''
        print(f"  - device={p.device} vid={p.vid} pid={p.pid} desc='{desc}' iface='{iface}' hwid='{p.hwid}'")

    def _pid_from_hwid(hw):
        try:
            hw = hw or ""
            token = "PID="
            if token in hw:
                rhs = hw.split(token, 1)[1]
                pid_str = rhs.split(":")[1].split()[0]
                return int(pid_str, 16)
        except Exception:
            pass
        return None

    if vid_hex and pid_hex:
        try:
            vid = int(vid_hex, 16)
            pid = int(pid_hex, 16)
        except Exception:
            vid = pid = None
        if vid is not None and pid is not None:
            for p in ports:
                try:
                    if p.vid == vid and p.pid == pid:
                        return p.device
                except Exception:
                    pass
            print(f"[SERIAL] No exact VID:PID match yet ({vid_hex}:{pid_hex}). Will keep scanning.")
            return None

    if vid_hex and not pid_hex:
        try:
            vid = int(vid_hex, 16)
        except Exception:
            vid = None
        candidates = []
        for p in ports:
            try:
                if p.vid == vid:
                    candidates.append(p)
            except Exception:
                pass
        if candidates:
            def _score(cp):
                cp_pid = getattr(cp, "pid", None)
                hw_pid = _pid_from_hwid(getattr(cp, "hwid", None)) if prefer_pid_from_hwid else None
                pid_val = cp_pid if cp_pid is not None else hw_pid
                if pid_val == 0x5750: return 0
                if pid_val == 0x5740: return 2
                return 1
            best = sorted(candidates, key=_score)[0]
            return best.device

    if allow_fuzzy_if_no_vidpid and not vid_hex and not pid_hex:
        hints = [h.lower() for h in [name_hint, "frsky", "serial", "stm", "vcp", "x20", "x18", "x14"] if h]
        for p in ports:
            desc = f"{p.description or ''} {getattr(p,'interface','') or ''}".lower()
            if any(h in desc for h in hints):
                return p.device

    return None


def _find_serial_debug_port(vid_hex=None, pid_hex=None, name_hint=None):
    """Return a likely serial debug device, preferring exact VID:PID matches."""
    port = _find_com_port(
        vid_hex=vid_hex,
        pid_hex=pid_hex,
        name_hint=name_hint,
        allow_fuzzy_if_no_vidpid=False,
    )
    if port:
        return port

    # macOS sometimes reports incomplete metadata during re-enumeration.
    return _find_com_port(
        vid_hex=None,
        pid_hex=None,
        name_hint=name_hint,
        allow_fuzzy_if_no_vidpid=True,
    )


def tail_serial_debug(vid=DEFAULT_SERIAL_VID, pid=DEFAULT_SERIAL_PID,
                      baud=DEFAULT_SERIAL_BAUD, retries=DEFAULT_SERIAL_RETRIES,
                      delay=DEFAULT_SERIAL_DELAY, newline=b'\n', name_hint="Serial"):
    try:
        import serial
    except Exception:
        print("[SERIAL] pyserial not installed. Install with: pip install pyserial")
        return 2

    time.sleep(1.5)

    port = None
    for i in range(retries):
        port = _find_serial_debug_port(vid_hex=vid, pid_hex=pid, name_hint=name_hint)
        if port:
            break
        print(f"[SERIAL] Waiting for serial port ({i+1}/{retries})…")
        time.sleep(delay)

    if not port:
        print("[SERIAL] No suitable COM port found. See the detected ports above.")
        return 3

    print(f"[SERIAL] Connecting to {port} @ {baud} …")
    open_attempts = 8
    for attempt in range(1, open_attempts+1):
        try:
            s = serial.Serial(port=port, baudrate=baud, timeout=0.5)
            break
        except FileNotFoundError as e:
            print(f"[SERIAL] Open attempt {attempt}/{open_attempts} -> device vanished; rescanning…")
            port = _find_serial_debug_port(vid_hex=vid, pid_hex=pid, name_hint=name_hint)
            if not port:
                import time as _t; _t.sleep(delay)
            continue
        except Exception as e:
            print(f"[SERIAL] Open attempt {attempt}/{open_attempts} failed: {e}")
            import time as _t; _t.sleep(delay)
            continue
    else:
        print("[SERIAL] Could not open any matching COM port after multiple attempts.")
        return 4

    try:
        with s:
            print("- Serial connected. Press Ctrl+C to stop -")
            buf = b""
            while True:
                try:
                    data = s.read(1024)
                    if data:
                        buf += data
                        while True:
                            if newline in buf:
                                line, buf = buf.split(newline, 1)
                                try:
                                    print(line.decode('utf-8', errors='replace'))
                                except Exception:
                                    print(line)
                            else:
                                break
                except KeyboardInterrupt:
                    print("[SERIAL] Stopped by user.")
                    return 0
    except KeyboardInterrupt:
        print("[SERIAL] Stopped by user.")
        return 0
    except Exception as e:
        print(f"[SERIAL] Error: {e}")
        return 4

# Copy with progress
def copy_verbose(src, dst):
    pbar.update(1)
    if DEPLOY_TO_RADIO:
        throttled_copyfile(src, dst)
        flush_fs()
    else:
        shutil.copy2(src, dst)


def count_files(dirpath, ext=None):
    total = 0
    for _, _, files in os.walk(dirpath):
        if ext:
            files = [f for f in files if f.endswith(ext)]
        total += len(files)
    return total

def run_step_script(step, out_dir, lang="en"):
    """
    Generic step runner.

    Conventions:
      - If `step` ends with '.py' or contains a path separator,
          treat it as a path (absolute or relative to git_src).
      - Otherwise, look for:
          <git_src>/.vscode/scripts/deploy_step_<step>.py
    The step script is called as:
      python <script> --out-dir OUT --lang LANG --git-src GIT_SRC
    """
    git_src = config["git_src"]

    # Determine script path
    if step.endswith(".py") or os.sep in step or "/" in step:
        script_path = step
        if not os.path.isabs(script_path):
            script_path = os.path.join(git_src, script_path)
    else:
        script_path = os.path.join(
            git_src, ".vscode", "scripts", f"deploy_step_{step}.py"
        )

    script_path = os.path.normpath(script_path)

    if not os.path.isfile(script_path):
        print(f"[STEP] Skipping '{step}': script not found at {script_path}")
        return

    cmd = [
        sys.executable,
        script_path,
        "--out-dir", out_dir,
        "--lang", lang,
        "--git-src", git_src,
    ]

    print(f"[STEP] Running '{step}' → {script_path}")
    try:
        subprocess.run(cmd, check=True)
    except subprocess.CalledProcessError as e:
        print(f"[STEP] Step '{step}' failed with exit code {e.returncode}")
    except Exception as e:
        print(f"[STEP] Step '{step}' crashed: {e}")


def run_steps(steps, out_dir, lang="en"):
    """Run all requested steps (if any) for this output directory."""
    if not steps:
        return
    ordered_steps = list(steps)
    menu_src = os.path.join(config["git_src"], "bin", "menu", "manifest.source.json")
    menu_gen = os.path.join(config["git_src"], "bin", "menu", "generate.py")
    if "menu" not in ordered_steps and os.path.isfile(menu_src) and os.path.isfile(menu_gen):
        ordered_steps.insert(0, "menu")
    for step in ordered_steps:
        run_step_script(step, out_dir, lang=lang)



def copy_files(src_override, fileext, targets, lang="en", steps=None):
    """
    Copy files to targets.

    For radio deploys, the most reliable approach is:
      1) stage into a local temp folder
      2) run step scripts (e.g. i18n) against the staged tree
      3) copy staged results to the mounted radio

    This avoids lots of tiny edits + verify cycles directly on removable storage.
    """
    global pbar
    git_src = src_override or config['git_src']
    tgt = config['tgt_name']
    print(f"Copy mode: {fileext or 'all'}")

    def _local_recreate_tree(src_dir: str, dst_dir: str):
        if os.path.isdir(dst_dir):
            shutil.rmtree(dst_dir, onerror=on_rm_error)
        os.makedirs(os.path.dirname(dst_dir), exist_ok=True)
        shutil.copytree(src_dir, dst_dir, dirs_exist_ok=True)

    def _stage_tree(src_dir: str):
        stage_root = _stage_mkdir(prefix="ethos-deploy-stage-")
        staged_out_dir = os.path.join(stage_root, tgt)
        _local_recreate_tree(src_dir, staged_out_dir)
        return stage_root, staged_out_dir

    def _fast_copy_from_stage(stage_dir: str, dest_dir: str):
        mirror_copy(stage_dir, dest_dir, delete_stale=True)

    for i, t in enumerate(targets, 1):
        dest = t['dest']; sim = t.get('simulator')
        print(f"[{i}/{len(targets)}] -> {t['name']} @ {dest}")

        if not os.path.isdir(dest):
            fallback = os.path.normpath(os.path.join(git_src, 'simulator', 'scripts'))
            try:
                os.makedirs(fallback, exist_ok=True)
                print(f"[DEST] '{dest}' not found. Using fallback: {fallback}")
                t['dest'] = fallback
                dest = fallback
            except Exception as e:
                print(f"[DEST ERROR] Could not create fallback folder at {fallback}: {e}")
                raise

        out_dir = os.path.join(dest, tgt)

        # Decide whether to stage locally (recommended for radio when running steps)
        do_stage = bool(DEPLOY_TO_RADIO and DEPLOY_STAGE and steps)

        # Always source from repo src/<tgt>
        repo_src = os.path.join(git_src, 'src', tgt)

        if do_stage:
            print("[STAGE] Staging to local temp, running steps, then copying to radio…")
            stage_root, staged_out_dir = _stage_tree(repo_src)

            # Run steps locally on staged tree
            run_steps(steps, staged_out_dir, lang)

            # Small settle time before hammering removable media
            print("[IO] Letting radio storage settle…")
            time.sleep(1.5)

            if fileext == 'fast':
                # Copy only changed files from stage -> radio
                _fast_copy_from_stage(staged_out_dir, out_dir)

            elif fileext == '.lua':
                # Keep old behavior: remove lua/luac on radio, then copy lua from stage
                if os.path.isdir(out_dir):
                    for r, _, files in os.walk(out_dir):
                        for f in files:
                            if f.endswith(('.lua', '.luac')):
                                try:
                                    os.remove(os.path.join(r, f))
                                except Exception:
                                    pass
                os.makedirs(out_dir, exist_ok=True)
                for r, _, files in os.walk(staged_out_dir):
                    for f in files:
                        if f.endswith('.lua'):
                            srcf = os.path.join(r, f)
                            rel = os.path.relpath(srcf, staged_out_dir)
                            dstf = os.path.join(out_dir, rel)
                            if DEPLOY_TO_RADIO:
                                throttled_copyfile(srcf, dstf)
                                flush_fs()
                                time.sleep(0.02)
                            else:
                                os.makedirs(os.path.dirname(dstf), exist_ok=True)
                                shutil.copy(srcf, dstf)

            else:
                # Full safe copy from stage -> radio
                safe_full_copy(staged_out_dir, out_dir)

            flush_fs()
            time.sleep(1.0)
            print(f"Done: {t['name']}")
            continue

        # --- legacy (non-staged) path ---------------------------------------
        if fileext == '.lua':
            if os.path.isdir(out_dir):
                for r, _, files in os.walk(out_dir):
                    for f in files:
                        if f.endswith(('.lua','.luac')):
                            os.remove(os.path.join(r,f))
            scr = repo_src
            os.makedirs(out_dir, exist_ok=True)
            for r,_,files in os.walk(scr):
                for f in files:
                    if f.endswith('.lua'):
                        shutil.copy(os.path.join(r,f), out_dir)

            run_steps(steps, out_dir, lang)

        elif fileext == 'fast':
            scr = repo_src
            mirror_copy(scr, out_dir, delete_stale=True)

            run_steps(steps, out_dir, lang)

        else:
            srcall = repo_src
            if DEPLOY_TO_RADIO:
                safe_full_copy(srcall, out_dir)
            else:
                mirror_copy(srcall, out_dir, delete_stale=True)
            run_steps(steps, out_dir, lang)
            flush_fs()
            time.sleep(2)

            print(f"Done: {t['name']}")

def patch_logger_init(out_root):
    import os, re
    target_file = os.path.join(out_root, 'tasks', 'logger', 'init.lua')
    try:
        if not os.path.exists(target_file):
            print(f"[PATCH] logger init.lua not found: {target_file}")
            return

        with open(target_file, 'r', encoding='utf-8', errors='replace') as f:
            lines = f.readlines()

        changed = 0
        key_re = re.compile(
            r'(?i)^(?P<indent>\s*)'
            r'(?P<key>(?:\[\s*["\']simulatoronly["\']\s*\]|simulatoronly))'
            r'(?P<between>\s*=\s*)'
            r'(?P<val>true)'
            r'(?P<after>\s*,?)'
        )

        for i, line in enumerate(lines):
            code, sep, comment = line.partition('--')
            m = key_re.search(code)
            if m:
                code = (
                    code[:m.start()] +
                    f"{m.group('indent')}{m.group('key')}{m.group('between')}false{m.group('after')}" +
                    code[m.end():]
                )
                lines[i] = code + (sep + comment if sep else '')
                changed += 1

        if changed:
            with open(target_file, 'w', encoding='utf-8', newline='') as f:
                f.writelines(lines)
            print(f"[PATCH] Set simulatoronly=false in {target_file} ({changed} change{'s' if changed!=1 else ''}).")
        else:
            print(f"[PATCH] No changes needed for {target_file} (already false or key missing).")
    except Exception as e:
        print(f"[PATCH] Failed to edit {target_file}: {e}")


def launch_sims(targets):
    if subprocess_conout is None:
        print("[SIM] subprocess_conout is unavailable on this platform; skipping simulator launch.")
        return
    for t in targets:
        sim = t.get('simulator')
        if sim:
            print(f"Launching {t['name']}: {sim}")
            out = subprocess_conout.subprocess_conout(sim, nrows=9999, encode=True)
            print(out)


def main():
    global DEPLOY_TO_RADIO
    p = argparse.ArgumentParser(description='Deploy & launch')
    p.add_argument(
        '--config',
        default=CONFIG_PATH,
        help='Optional path to a JSON config file (Ethos/serial settings).'
    )
    p.add_argument('--src')
    p.add_argument('--fileext')
    p.add_argument('--all', action='store_true')
    p.add_argument('--launch', action='store_true')
    p.add_argument('--radio', action='store_true')
    p.add_argument('--radio-debug', action='store_true')
    p.add_argument('--no-stage', action='store_true',
                   help='Disable local staging; run steps directly on destination (not recommended for radio).')
    p.add_argument('--connect-only', action='store_true')
    p.add_argument('--lang', default=os.environ.get("ETHOS_DEPLOY_LANG", "en"),
                   help='Locale to resolve (e.g. en, de, fr). Defaults to env ETHOS_DEPLOY_LANG or "en".')
    p.add_argument('--force', action='store_true',
                   help='Take over a stale single-instance lock if the previous run crashed.')
    p.add_argument('--clear-lock', action='store_true',
                   help='Delete ONLY the current project lock and exit.')
    p.add_argument('--clear-all-locks', action='store_true',
                   help='Delete ALL deploy-*.lock files in the system temp and exit.')
    p.add_argument('--print-lock', action='store_true',
                   help='Print the lock file path for this project and exit.')
    p.add_argument('--step', dest='steps', action='append',
                   help='Additional deploy steps to run (e.g. i18n, soundpack). '
                        'Can be given multiple times.'
    )

    args = p.parse_args()
    DEPLOY_TO_RADIO = args.radio

    global DEPLOY_STAGE
    DEPLOY_STAGE = _staging_is_enabled(args)
    DEPLOY_PIDFILE = os.path.join(tempfile.gettempdir(), "deploy-copy.pid")
    try:
        with open(DEPLOY_PIDFILE, "w") as f:
            f.write(str(os.getpid()))
    except Exception:
        pass
    atexit.register(lambda: os.path.exists(DEPLOY_PIDFILE) and os.remove(DEPLOY_PIDFILE))

    if args.config and os.path.abspath(args.config) != os.path.abspath(CONFIG_PATH) and os.path.exists(args.config):
        try:
            with open(args.config) as f:
                override_cfg = json.load(f)
            if isinstance(override_cfg, dict):
                config.update(override_cfg)
                # NEW: Debug which override config file is loaded
                print(f"[CONFIG] Loaded override config file: {os.path.abspath(args.config)}")
            else:
                print(f"[CONFIG WARN] Override config at {args.config} is not a JSON object; ignoring.")
        except json.JSONDecodeError as e:
            print(f"[CONFIG WARN] Failed to parse override JSON config file at {args.config}: {e}")

    # NEW: Always show the effective config source used for locks & overrides
    print(f"[CONFIG] Effective config source (for locks & overrides): {os.path.abspath(args.config)}")

    if args.print_lock:
        print(_lock_path_for_config(args.config))
        return 0

    if args.clear_all_locks:
        tmp = tempfile.gettempdir()
        removed = 0
        for f in glob(os.path.join(tmp, "deploy-*.lock")):
            try:
                os.remove(f)
                print(f"Removed: {f}")
                removed += 1
            except Exception as e:
                print(f"Could not remove: {f} — {e}", file=sys.stderr)
        print(f"Removed {removed} lock file(s) from {tmp}")
        return 0

    if args.clear_lock:
        path = _lock_path_for_config(args.config)
        try:
            os.remove(path)
            print(f"Removed: {path}")
            return 0
        except FileNotFoundError:
            print(f"No lock found: {path}")
            return 0
        except Exception as e:
            print(f"Could not remove: {path} — {e}", file=sys.stderr)
            return 1

    proj_key = md5(os.path.abspath(args.config).encode("utf-8")).hexdigest()[:8]
    lock_name = f"deploy-{proj_key}.lock"
    try:
        SingleInstance(name=lock_name, force=args.force).acquire()
    except RuntimeError as e:
        print(str(e), file=sys.stderr)
        return 1

    ethos_bin = config.get('ethossuite_bin')
    if ethos_bin and not check_ethossuite_version(ethos_bin, min_version=MIN_ETHOSSUITE_VERSION):
        if args.radio:
            return 1
        print("[WARN] Ethos Suite version check failed; continuing because simulator deploy does not require Ethos Suite.")

    # --- target selection: RADIO vs SIMULATOR ---------------------------------
    targets = []

    if args.radio and args.connect_only:
        # Just enable serial & tail logs; no copying
        v = str(config.get('serial_vid', DEFAULT_SERIAL_VID))
        p = str(config.get('serial_pid', DEFAULT_SERIAL_PID))
        b = int(config.get('serial_baud', DEFAULT_SERIAL_BAUD))
        r = int(config.get('serial_retries', DEFAULT_SERIAL_RETRIES))
        d = float(config.get('serial_retry_delay', DEFAULT_SERIAL_DELAY))
        nh = str(config.get('serial_name_hint', "Serial"))

        existing_port = _find_serial_debug_port(vid_hex=v, pid_hex=p, name_hint=nh)
        if existing_port:
            print(f"[SERIAL] Existing serial debug port detected: {existing_port}; skipping HID mode switch.")
        else:
            rc, _, _ = ethos_serial(config.get('ethossuite_bin'), 'start')
            if rc != 0:
                print("[SERIAL] USB debug start unavailable; continuing to probe for a serial port anyway.")

        return tail_serial_debug(vid=v, pid=p, baud=b, retries=r, delay=d, name_hint=nh)

    if args.radio and not args.connect_only:
        # RADIO DEPLOY: use Ethos Suite to locate the radio SCRIPTS path
        print("[ETHOS] Disabling serial debug before copy to protect filesystem…")
        ethos_serial(config.get('ethossuite_bin'), 'stop')
        try:
            rd = wait_for_scripts_mount(config.get('ethossuite_bin'), attempts=10, delay=2)
        except Exception as e:
            print("[ERROR] Failed to obtain Ethos SCRIPTS path after disabling serial.")
            print(f"        Reason: {e}")
            try:
                import winsound
                winsound.MessageBeep()
            except Exception:
                print("\a", end="", flush=True)
            return 1

        targets = [{'name': 'Radio', 'dest': rd, 'simulator': None}]
    else:
        # SIMULATOR DEPLOY: always to <git_src>\simulator\[firmware]\scripts
        firmware = os.environ.get("ETHOS_FIRMWARE")
        path_parts = [config['git_src'], 'simulator']
        if firmware:
            path_parts.append(firmware)
        path_parts.append('scripts')

        fixed_dest = os.path.normpath(os.path.join(*path_parts))
        os.makedirs(fixed_dest, exist_ok=True)
        targets = [{'name': 'Simulator', 'dest': fixed_dest, 'simulator': None}]

    # -------------------------------------------------------------------------
    copy_files(args.src, args.fileext, targets, lang=args.lang, steps=args.steps)

    if args.launch and not args.radio:
        launch_sims(targets)

    if args.radio and not args.radio_debug:
        ethos_serial(config.get('ethossuite_bin'), 'start')

    if args.radio and args.radio_debug:
        _kill_previous_tail_if_any()
        v = str(config.get('serial_vid', DEFAULT_SERIAL_VID))
        p = str(config.get('serial_pid', DEFAULT_SERIAL_PID))
        b = int(config.get('serial_baud', DEFAULT_SERIAL_BAUD))
        r = int(config.get('serial_retries', DEFAULT_SERIAL_RETRIES))
        d = float(config.get('serial_retry_delay', DEFAULT_SERIAL_DELAY))
        nh = str(config.get('serial_name_hint', "Serial"))

        existing_port = _find_serial_debug_port(vid_hex=v, pid_hex=p, name_hint=nh)
        if existing_port:
            print(f"[SERIAL] Existing serial debug port detected: {existing_port}; skipping HID mode switch.")
        else:
            rc, _, _ = ethos_serial(config.get('ethossuite_bin'), 'start')
            if rc != 0:
                print("[ETHOS] First --serial start failed; retrying once…")
                rc, _, _ = ethos_serial(config.get('ethossuite_bin'), 'start')
                if rc != 0:
                    print("[SERIAL] USB debug start unavailable; continuing to probe for a serial port anyway.")

        tail_serial_debug(vid=v, pid=p, baud=b, retries=r, delay=d, name_hint=nh)

if __name__ == '__main__':
    rc = main()
    try:
        sys.exit(rc if isinstance(rc, int) else 0)
    except SystemExit:
        pass
