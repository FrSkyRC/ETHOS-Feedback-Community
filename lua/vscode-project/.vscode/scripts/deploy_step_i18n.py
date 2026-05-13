#!/usr/bin/env python
import os
import sys
import argparse
import subprocess
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(
        description="Resolve @i18n(...)@ tags for a given output dir + language."
    )
    parser.add_argument("--out-dir", required=True, help="Output directory (root of the deployed script tree).")
    parser.add_argument("--lang", default="en", help="Language code, e.g. en, fr, de.")
    parser.add_argument(
        "--git-src",
        help="Workspace root; if omitted, will be inferred from this script location.",
    )
    args = parser.parse_args()

    out_dir = os.path.abspath(args.out_dir)
    lang = args.lang

    if args.git_src:
        git_src = os.path.abspath(args.git_src)
    else:
        # Assume this script is: <git_src>/.vscode/scripts/deploy_step_i18n.py
        git_src = str(Path(os.path.abspath(__file__)).parents[2])

    # Try language JSON in out_dir first, then fall back to common source locations.
    json_path = os.path.join(out_dir, "i18n", f"{lang}.json")
    if not os.path.isfile(json_path):
        target_name = os.path.basename(out_dir.rstrip(os.sep))
        fallback_paths = [
            os.path.join(git_src, "src", target_name, "i18n", f"{lang}.json"),
            os.path.join(git_src, "scripts", target_name, "i18n", f"{lang}.json"),
        ]
        json_path = next((path for path in fallback_paths if os.path.isfile(path)), json_path)

    if not os.path.isfile(json_path):
        print(f"[I18N] Skipping: {lang}.json not found at {json_path}")
        return 0

    resolver = os.path.join(git_src, ".vscode", "scripts", "resolve_i18n_tags.py")
    if not os.path.isfile(resolver):
        print(f"[I18N] Skipping: resolver not found at {resolver}")
        return 0

    print(f"[I18N] Resolving @i18n(...)@ tags (lang={lang})…")
    subprocess.run(
        [sys.executable, resolver, "--json", json_path, "--root", out_dir],
        check=True,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
