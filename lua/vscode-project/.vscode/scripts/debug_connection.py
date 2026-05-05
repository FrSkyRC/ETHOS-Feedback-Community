#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import glob
import json
import os
import platform
import subprocess
import sys
import time


ETHOS_VENDOR_ID = 0x0483


def _print_header(title):
    print(f"\n=== {title} ===")


def _run_command(cmd):
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
        print(f"$ {' '.join(cmd)}")
        if result.stdout.strip():
            print(result.stdout.strip())
        if result.stderr.strip():
            print("[stderr]")
            print(result.stderr.strip())
        print(f"[exit={result.returncode}]")
    except Exception as exc:
        print(f"$ {' '.join(cmd)}")
        print(f"[error] {type(exc).__name__}: {exc}")


def _list_volumes():
    volumes = []
    for base in ("/Volumes", "/media", "/mnt"):
        if not os.path.isdir(base):
            continue
        for entry in sorted(os.listdir(base)):
            root = os.path.join(base, entry)
            if not os.path.isdir(root):
                continue
            markers = []
            for key in ("flash", "sdcard", "radio"):
                if os.path.exists(os.path.join(root, f"{key}.cpuid")):
                    markers.append(key)
            if markers or os.path.isdir(os.path.join(root, "scripts")):
                volumes.append(
                    {
                        "root": root,
                        "markers": markers,
                        "scripts": os.path.isdir(os.path.join(root, "scripts")),
                    }
                )
    return volumes


def _list_serial_ports():
    try:
        from serial.tools import list_ports
    except Exception as exc:
        return {"error": f"{type(exc).__name__}: {exc}", "ports": []}

    ports = []
    for port in list(list_ports.comports()):
        ports.append(
            {
                "device": port.device,
                "vid": port.vid,
                "pid": port.pid,
                "description": port.description,
                "interface": getattr(port, "interface", None),
                "hwid": port.hwid,
            }
        )
    return {"ports": ports}


def _list_hid_devices():
    try:
        import hid
    except Exception as exc:
        return {"error": f"{type(exc).__name__}: {exc}", "devices": []}

    devices = []
    try:
        for dev in hid.enumerate():
            if dev.get("vendor_id") != ETHOS_VENDOR_ID:
                continue
            devices.append(
                {
                    "vendor_id": dev.get("vendor_id"),
                    "product_id": dev.get("product_id"),
                    "path": str(dev.get("path")),
                    "product_string": dev.get("product_string"),
                    "manufacturer_string": dev.get("manufacturer_string"),
                    "serial_number": dev.get("serial_number"),
                    "interface_number": dev.get("interface_number"),
                    "usage_page": dev.get("usage_page"),
                    "usage": dev.get("usage"),
                }
            )
    except Exception as exc:
        return {"error": f"{type(exc).__name__}: {exc}", "devices": []}

    return {"devices": devices}


def _probe_connect_module():
    try:
        import connect
    except Exception as exc:
        return {"import_error": f"{type(exc).__name__}: {exc}"}

    result = {"import_ok": True}
    radio = None
    try:
        radio = connect.RadioInterface()
        result["radio_interface"] = type(radio).__name__
        result["drives"] = dict(getattr(radio, "drives", {}))
    except Exception as exc:
        result["open_error"] = f"{type(exc).__name__}: {exc}"
    finally:
        try:
            if radio is not None:
                radio.close()
        except Exception:
            pass
    return result


def _switch_usb_mode(action, wait_s):
    result = {"requested_action": action, "wait_s": wait_s}
    try:
        import connect
    except Exception as exc:
        result["import_error"] = f"{type(exc).__name__}: {exc}"
        return result

    radio = None
    try:
        radio = connect.RadioInterface()
        result["radio_interface"] = type(radio).__name__
        result["drives_before"] = dict(getattr(radio, "drives", {}))
        if action == "start":
            radio.start_usb_debug()
        elif action == "stop":
            radio.stop_usb_debug()
        else:
            raise ValueError(f"Unsupported action: {action}")
        result["switch_invoked"] = True
    except Exception as exc:
        result["switch_error"] = f"{type(exc).__name__}: {exc}"
        return result
    finally:
        try:
            if radio is not None:
                radio.close()
        except Exception:
            pass

    time.sleep(wait_s)
    result["post_wait"] = {
        "volumes": _list_volumes(),
        "serial": _list_serial_ports(),
        "hid": _list_hid_devices(),
        "dev_cu": sorted(glob.glob("/dev/cu.*")),
        "dev_tty": sorted(glob.glob("/dev/tty.*")),
        "connect": _probe_connect_module(),
    }
    return result


def main():
    parser = argparse.ArgumentParser(description="Debug Ethos radio USB/HID/serial state")
    parser.add_argument("--json", action="store_true", help="Emit machine-readable JSON")
    parser.add_argument(
        "--switch",
        choices=("start", "stop"),
        help="Actively request a USB mode switch through connect.py before collecting state.",
    )
    parser.add_argument(
        "--wait",
        type=float,
        default=3.0,
        help="Seconds to wait after --switch before collecting post-switch state.",
    )
    args = parser.parse_args()

    payload = {
        "platform": {
            "system": platform.system(),
            "release": platform.release(),
            "version": platform.version(),
            "machine": platform.machine(),
            "python": sys.version,
        },
        "volumes": _list_volumes(),
        "serial": _list_serial_ports(),
        "hid": _list_hid_devices(),
        "connect": _probe_connect_module(),
        "dev_cu": sorted(glob.glob("/dev/cu.*")),
        "dev_tty": sorted(glob.glob("/dev/tty.*")),
    }

    if args.switch:
        payload["switch_probe"] = _switch_usb_mode(args.switch, args.wait)

    if args.json:
        print(json.dumps(payload, indent=2, sort_keys=True))
        return 0

    _print_header("Platform")
    print(json.dumps(payload["platform"], indent=2))

    _print_header("Volumes")
    if payload["volumes"]:
        for item in payload["volumes"]:
            print(json.dumps(item, indent=2))
    else:
        print("No candidate mounted radio volumes found.")

    _print_header("Serial Ports")
    if payload["serial"].get("error"):
        print(payload["serial"]["error"])
    elif payload["serial"]["ports"]:
        for item in payload["serial"]["ports"]:
            print(json.dumps(item, indent=2))
    else:
        print("No serial ports found.")

    _print_header("HID Devices")
    if payload["hid"].get("error"):
        print(payload["hid"]["error"])
    elif payload["hid"]["devices"]:
        for item in payload["hid"]["devices"]:
            print(json.dumps(item, indent=2))
    else:
        print(f"No HID devices found for vendor 0x{ETHOS_VENDOR_ID:04X}.")

    _print_header("Connect Module Probe")
    print(json.dumps(payload["connect"], indent=2))

    if payload.get("switch_probe") is not None:
        _print_header("Switch Probe")
        print(json.dumps(payload["switch_probe"], indent=2))

    if platform.system() == "Darwin":
        _print_header("macOS USB Snapshot")
        _run_command(["system_profiler", "SPUSBDataType"])
        _print_header("macOS IORegistry Snapshot")
        _run_command(["ioreg", "-p", "IOUSB", "-l", "-w", "0"])

    _print_header("Device Nodes")
    print("/dev/cu.*")
    for item in payload["dev_cu"]:
        print(item)
    print("/dev/tty.*")
    for item in payload["dev_tty"]:
        print(item)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
