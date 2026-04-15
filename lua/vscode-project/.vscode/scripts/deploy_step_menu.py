#!/usr/bin/env python
import argparse
import os
import subprocess
import sys
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(
        description="Generate menu manifest from JSON source into the staged deploy tree."
    )
    parser.add_argument("--out-dir", required=True, help="Output directory root.")
    parser.add_argument("--lang", default="en", help="Unused for this step; kept for step API compatibility.")
    parser.add_argument(
        "--git-src",
        help="Workspace root; if omitted, inferred from script location.",
    )
    args = parser.parse_args()

    out_dir = os.path.abspath(args.out_dir)
    if args.git_src:
        git_src = os.path.abspath(args.git_src)
    else:
        git_src = str(Path(__file__).resolve().parents[2])

    source_json = os.path.join(git_src, "bin", "menu", "manifest.source.json")
    generator = os.path.join(git_src, "bin", "menu", "generate.py")

    if os.path.isdir(os.path.join(out_dir, "rfsuite")):
        output_lua = os.path.join(out_dir, "rfsuite", "app", "modules", "manifest.lua")
    else:
        output_lua = os.path.join(out_dir, "app", "modules", "manifest.lua")

    if not os.path.isfile(source_json):
        print(f"[MENU] Skipping: source not found at {source_json}")
        return 0

    if not os.path.isfile(generator):
        print(f"[MENU] Skipping: generator not found at {generator}")
        return 0

    print(f"[MENU] Generating manifest.lua into {output_lua}")
    subprocess.run(
        [sys.executable, generator, "--source", source_json, "--output", output_lua],
        check=True,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
