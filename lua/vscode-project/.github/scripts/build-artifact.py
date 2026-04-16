#!/usr/bin/env python3
import argparse
import json
import os
import shutil
import subprocess
import sys
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
CONFIG_PATH = ROOT / ".vscode" / "deploy.json"


def load_config():
    with CONFIG_PATH.open("r", encoding="utf-8") as handle:
        data = json.load(handle)
    if not isinstance(data, dict):
        raise ValueError(f"{CONFIG_PATH} must contain a JSON object")
    return data


def run_step(step_name: str, out_dir: Path, lang: str):
    script = ROOT / ".vscode" / "scripts" / f"deploy_step_{step_name}.py"
    if not script.is_file():
        print(f"[CI] Step '{step_name}' skipped: missing script {script}")
        return
    cmd = [
        sys.executable,
        str(script),
        "--out-dir",
        str(out_dir),
        "--lang",
        lang,
        "--git-src",
        str(ROOT),
    ]
    print(f"[CI] Running step '{step_name}'")
    subprocess.run(cmd, check=True)


def should_run_i18n(stage_dir: Path, lang: str) -> bool:
    return (stage_dir / "i18n" / f"{lang}.json").is_file()


def should_run_menu() -> bool:
    return (ROOT / "bin" / "menu" / "manifest.source.json").is_file() and (
        ROOT / "bin" / "menu" / "generate.py"
    ).is_file()


def should_run_soundpack(lang: str) -> bool:
    lang_dir = ROOT / "bin" / "sound-generator" / "soundpack" / lang
    fallback_dir = ROOT / "bin" / "sound-generator" / "soundpack" / "en"
    return lang_dir.is_dir() or fallback_dir.is_dir()


def zip_tree(source_root: Path, zip_path: Path):
    with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for file_path in sorted(source_root.rglob("*")):
            if file_path.is_file():
                archive.write(file_path, file_path.relative_to(source_root))


def main():
    parser = argparse.ArgumentParser(description="Build a ZIP artifact from the VS Code Ethos template.")
    parser.add_argument("--lang", default="en", help="Locale to package.")
    parser.add_argument("--version-suffix", default="dev", help="Version label for the artifact filename.")
    parser.add_argument("--artifact-name", default="ethos-lua-project", help="Artifact filename prefix.")
    parser.add_argument(
        "--step",
        dest="steps",
        action="append",
        default=[],
        help="Optional deploy steps to run, for example: i18n, menu, soundpack, sensors.",
    )
    args = parser.parse_args()

    config = load_config()
    tgt_name = config.get("tgt_name")
    if not tgt_name:
        raise SystemExit("[CI] Missing 'tgt_name' in .vscode/deploy.json")

    src_dir = ROOT / "src" / tgt_name
    if not src_dir.is_dir():
        raise SystemExit(f"[CI] Source folder not found: {src_dir}")

    build_dir = ROOT / "build" / args.lang
    scripts_dir = build_dir / "scripts"
    stage_dir = scripts_dir / tgt_name
    artifact_dir = ROOT / "build" / "artifacts"
    artifact_dir.mkdir(parents=True, exist_ok=True)

    if stage_dir.exists():
        shutil.rmtree(stage_dir)
    scripts_dir.mkdir(parents=True, exist_ok=True)
    shutil.copytree(src_dir, stage_dir)

    for step_name in args.steps:
        if step_name == "i18n" and not should_run_i18n(stage_dir, args.lang):
            print(f"[CI] Step '{step_name}' skipped: no i18n file for lang '{args.lang}'")
            continue
        if step_name == "menu" and not should_run_menu():
            print(f"[CI] Step '{step_name}' skipped: no menu generator found")
            continue
        if step_name == "soundpack" and not should_run_soundpack(args.lang):
            print(f"[CI] Step '{step_name}' skipped: no soundpack found")
            continue
        run_step(step_name, stage_dir, args.lang)

    zip_name = f"{args.artifact_name}-{args.version_suffix}-{args.lang}.zip"
    zip_path = artifact_dir / zip_name
    if zip_path.exists():
        zip_path.unlink()
    zip_tree(scripts_dir, zip_path)

    print(f"[CI] Created {zip_path}")
    print(f"artifact_path={zip_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
