# Setup Notes

## What This Template Contains

- `.vscode/tasks.json`: deploy tasks for simulator and radio
- `.vscode/launch.json`: launch profiles that wrap the deploy tasks
- `.vscode/deploy.json`: project-specific deploy settings
- `.vscode/scripts/`: Python helper scripts
- `.github/workflows/`: starter GitHub Actions workflows
- `.github/scripts/build-artifact.py`: CI packaging helper
- `src/sampleapp/`: starter source tree that you can rename
- `requirements.txt`: pip packages used by the deploy helpers

## Recommended VS Code Extensions

Install these first:

- `Ethos` by `bsongis` for simulator commands and telemetry windows
- `Python` by Microsoft
- `Python Debugger` by Microsoft

- This is the marketplace entry: `https://marketplace.visualstudio.com/items?itemName=bsongis.ethos`

The bundled `.vscode/extensions.json` recommends both the Ethos extension and the Microsoft Python extensions automatically. It also recommends `sumneko.lua` to get autocomplete/lint using [ethos-lua-definitions](https://github.com/flyingeek/ethos-lua-definitions)

## Python Setup

### Windows

PowerShell example:

```powershell
py -m pip install --upgrade pip
py -m pip install -r requirements.txt
```

Manual package install example:

```powershell
py -m pip install tqdm
py -m pip install pyserial
py -m pip install pywin32
py -m pip install hid
py -m pip install debugpy
```

Virtual environment example:

```powershell
py -m venv .venv
.venv\Scripts\Activate.ps1
py -m pip install --upgrade pip
py -m pip install -r requirements.txt
```

### macOS

macOS requires the native `hidapi` library for USB HID support:

```bash
# Install hidapi system library
brew install hidapi

# Create and activate virtual environment
python3 -m venv .venv
source .venv/bin/activate

# Install Python packages
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
```

The `pywin32` package is platform-specific and will not install on macOS (it is skipped automatically by pip).

In VS Code you must have installed the `Python` by Microsoft, and it is recommended to perform a complete restart of VSCode after (At least Command Palette/Developer: `Reload Window`). Then open Command Palette and use `Python: Set Interpreter`, choose the python in .venv.

### Packages used by the deploy tooling:

- `tqdm`: progress bars during copy/update
- `pyserial`: serial debug console support
- `hid`: direct USB mode switching for Ethos radios
- `pywin32`: Windows drive detection helpers used by `connect.py` (Windows only)
- `debugpy`: keeps VS Code launch/debug integration happy

Use `pyserial`, not `serial`, for the serial package install.

## Windows HID Setup

If `hid` installs but radio control still fails, copy the correct `hidapi.dll` for your machine into `C:\Windows\System32`.

Reference package:

- https://github.com/libusb/hidapi/releases/tag/hidapi-0.15.0

Windows note:

- install the package above
- copy the DLLs for your architecture into `C:\Windows\System32`

## macOS Radio Deployment Support

Radio deployment on macOS works by discovering radio volumes mounted at `/Volumes` and using USB HID for mode switching. The following applies:

**Supported:**
- ✓ Simulator file deployment (same as Windows/Linux)
- ✓ Radio USB HID mode switching (`start_usb_debug()`, `stop_usb_debug()`)
- ✓ Radio drive discovery via mounted volumes (when radio is mounted)
- ✓ File copying to mounted radio storage

**Not Available:**
- ✗ Windows-style volume locking (FSCTL_LOCK_VOLUME) — not provided by macOS kernel
- ✗ Direct volume ejection via `diskutil` is attempted but not guaranteed (best-effort)

**Practical Notes:**
- The Ethos radio's firmware is designed to handle filesystem operations correctly regardless of OS volume locking state
- The deployment workflow is sequential and user-initiated, so concurrent access conflicts are unlikely
- If a radio volume is not discovered, the fallback behavior in `deploy.py` will retry and report diagnostics

If you prefer to use Ethos Suite instead of direct HID control, add an `ethossuite_bin` entry to `.vscode/deploy.json`.

Example:

```json
{
  "tgt_name": "sampleapp",
  "ethossuite_bin": "C:/Program Files/Ethos Suite/ethos.exe"
}
```

## First Customization Pass

Before using this for a real project:

1. Rename `src/sampleapp` to your project folder name.
2. Update `.vscode/deploy.json` so `tgt_name` matches that folder exactly.
3. Replace the sample Lua files with your real project files.
4. Update `.vscode/settings.json` if you want a different default firmware.

## Folder Conventions

Expected core layout:

```text
vscode-project/
  .vscode/
  src/
    sampleapp/
      main.lua
  simulator/
```

Optional folders supported by the helper scripts:

- `src/<tgt>/i18n/<lang>.json`
- `.vscode/sensors.json`

If those optional folders do not exist, the helper scripts skip them cleanly.

You may override the stucture in deploy.json by setting the "src_dir" and "simulators_dir".

## Running The Template

Simulator file deploy:

1. Run `Deploy [SIM Files]`.
2. Check `simulator/<firmware>/scripts/<tgt_name>/`.

Simulator launch through VS Code:

1. Make sure the `bsongis.ethos` extension is installed and working.
2. Run `Deploy & Launch [SIM]`.

Radio deploy:

1. Connect the radio over USB.
2. Run `Deploy Radio` or `Deploy Radio [Fast]`.
3. Use `Deploy Radio + Serial Debug` if you want the serial console right after deploy.

Serial-only debug:

1. Run `Radio: Serial Debug`.
2. Stop it with `Ctrl+C`.

## GitHub Workflow Starter Files

The template includes:

- `.github/workflows/pr.yml`
- `.github/workflows/push.yml`
- `.github/workflows/release.yml`

These are intentionally generic:

- `pr.yml` builds ZIP artifacts for pull requests
- `push.yml` builds ZIP artifacts for `main` and `master`
- `release.yml` creates a GitHub release for tags matching `release/*`

All three call `.github/scripts/build-artifact.py`, which:

- reads `.vscode/deploy.json`
- stages `src/<tgt_name>` into `build/<lang>/scripts/<tgt_name>`
- creates a ZIP in `build/artifacts/`

You will usually want to customize:

- the language matrix in each workflow
- the release tag pattern
- the artifact naming convention
- any optional `--step` arguments if your project uses i18n or simulator sensors

## Default Config Files

`.vscode/deploy.json`

```json
{
  "tgt_name": "sampleapp",
  "src_dir": "src"
  "serial_vid": "0483",
  "serial_pid": "5750",
  "serial_baud": 115200,
  "serial_retries": 10,
  "serial_retry_delay": 1.0,
  "serial_name_hint": "FrSky",
  "use_ethossuite": false
}
```

`.vscode/settings.json`

```json
{
  "ethos.firmware": "X20S_FCC",
  "ethos.root": "simulator/${config:ethos.firmware}",
  "ethos.version": "nightly26"
}
```

## Optional Step Scripts

The deploy helpers support these step names:

- `i18n`: resolves `@i18n(...)@` tags using `src/<tgt>/i18n/<lang>.json`
- `sensors`: copies `.vscode/sensors.json` to the simulator root

Add them in `tasks.json` like this:

```json
"args": [
  "${workspaceFolder}/.vscode/scripts/deploy.py",
  "--step",
  "i18n",
  "--step",
  "sensors"
]
```

The foundation template does not enable any of these by default.

## Troubleshooting

`Another deploy is already running`

- Run the `Clear locks` task once.

`pyserial not installed`

- Run `py -m pip install pyserial`

`hid module needed`

- Run `py -m pip install hid`

`hidapi.dll is missing` (Windows)

- Copy the correct `hidapi.dll` into `C:\Windows\System32`

`Unable to load any of the following libraries: libhidapi...` (macOS)

- On macOS, the native hidapi library must be installed: `brew install hidapi`

`ethos.start` command not found

- Install or re-enable the `bsongis.ethos` VS Code extension

`Python was not found`

- Install Python 3 for your platform and reopen VS Code
