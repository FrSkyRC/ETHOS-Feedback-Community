# VS Code Ethos Deploy Template

This folder is a reusable starter for the VS Code deployment workflow used across several Ethos Lua projects.

It gives you:

- a ready-made `.vscode/` deploy setup
- Python helper scripts for simulator and radio deployment
- a sample `src/<target>` layout
- starter `.github/workflows/` files for PR, push, and release packaging
- setup notes for Python, pip, VS Code extensions, and Windows HID support

Start with [docs/setup.md](docs/setup.md).

## Quick Start

1. Open this folder in VS Code.
2. Install the recommended extensions from `.vscode/extensions.json`.
   Make sure this includes the Ethos simulator extension: `bsongis.ethos`.
3. Install Python packages:

   ```powershell
   py -m pip install --upgrade pip
   py -m pip install -r requirements.txt
   ```

4. Edit `.vscode/deploy.json` and set `tgt_name` to your real script folder name.
5. Rename `src/sampleapp` to match the same `tgt_name`.
6. Run `Tasks: Run Task` and choose `Deploy [SIM Files]`.

The deploy script will copy:

- `src/<tgt_name>/...`
- into `simulator/<firmware>/scripts/<tgt_name>/...`

If the Ethos VS Code extension is installed, you can also use `Deploy & Launch [SIM]`.

## GitHub Actions

The template now also includes starter workflows under `.github/workflows/`:

- `pr.yml`
- `push.yml`
- `release.yml`

They use `.github/scripts/build-artifact.py` to stage `src/<tgt_name>` and produce ZIP artifacts. No extra deploy steps run by default, which keeps the foundation plain and reusable.

## Template Notes

- Local deploy is plain file copy by default.
- Optional `i18n` and `sensors` helpers are included for projects that need them.
- Radio deploy and serial debug support are included for Windows-based setups.
