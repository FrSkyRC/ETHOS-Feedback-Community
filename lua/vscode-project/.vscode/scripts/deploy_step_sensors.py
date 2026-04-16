#!/usr/bin/env python
import os
import argparse
from pathlib import Path
import shutil
import sys


def debug(msg):
    print(f"[SENSORS DEBUG] {msg}")


def main():
    parser = argparse.ArgumentParser(
        description="Ensure sensors.json exists in the simulator root directory."
    )
    parser.add_argument("--out-dir", required=True, help="Output directory (scripts/<tgt>)")
    parser.add_argument("--lang")
    parser.add_argument("--git-src")
    args = parser.parse_args()

    # out_dir will be: simulator/<fw>/scripts/<tgt>
    out_dir = Path(args.out_dir).resolve()
    debug(f"Given out_dir = {out_dir}")

    # We want: simulator/<fw>/
    sim_root = out_dir.parents[1]   # one levels up
    debug(f"Computed simulator root = {sim_root}")

    if args.git_src:
        git_src = Path(args.git_src).resolve()
    else:
        git_src = Path(__file__).resolve().parents[2]

    src = git_src / ".vscode" / "sensors.json"
    dst = sim_root / "sensors.json"

    debug(f"Source sensors.json = {src} (exists={src.is_file()})")
    debug(f"Destination sensors.json = {dst} (exists={dst.is_file()})")

    if not src.is_file():
        print(f"[SENSORS] No source sensors.json found at {src}")
        return 0

    if dst.is_file():
        print(f"[SENSORS] sensors.json already exists at simulator root — leaving untouched.")
        return 0

    try:
        shutil.copy2(src, dst)
        print(f"[SENSORS] Copied sensors.json → {dst}")
    except Exception as e:
        print(f"[SENSORS] Copy failed: {e}")
        import traceback
        traceback.print_exc()
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
