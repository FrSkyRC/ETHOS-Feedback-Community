# VS Code Ethos Deploy Template

This folder is a reusable starter for the VS Code deployment workflow used across several Ethos Lua projects.

It gives you:

- a ready-made `.vscode/` deploy setup
- Python helper scripts for simulator and radio deployment
- a sample `src/<target>` layout
- example i18n files
- setup notes for Python, pip, VS Code extensions, and Windows HID support

Start with [docs/setup.md](docs/setup.md).

## Quick Start

1. Open this folder in VS Code.
2. Install the recommended extensions from `.vscode/extensions.json`.
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

## Template Notes

- `i18n` is enabled in the default deploy tasks.
- `sensors.json` is copied into the simulator root on simulator deploys.
- `menu` and `soundpack` helper scripts are included, but they only run when the matching folders exist or when you add the relevant deploy steps.
- Radio deploy and serial debug support are included for Windows-based setups.
