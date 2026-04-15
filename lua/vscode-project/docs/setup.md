# Setup Notes

## What This Template Contains

- `.vscode/tasks.json`: deploy tasks for simulator and radio
- `.vscode/launch.json`: launch profiles that wrap the deploy tasks
- `.vscode/deploy.json`: project-specific deploy settings
- `.vscode/scripts/`: Python helper scripts
- `src/sampleapp/`: starter source tree that you can rename
- `requirements.txt`: pip packages used by the deploy helpers

## Recommended VS Code Extensions

Install these first:

- `Python` by Microsoft
- `Python Debugger` by Microsoft
- the `Ethos` extension you already use for `ethos.start`, `ethos.setFirmware`, `ethos.setRoot`, and `ethos.openTelemetry`

The bundled `.vscode/extensions.json` recommends the Microsoft Python extensions automatically.

## Python Setup

PowerShell example:

```powershell
py -m pip install --upgrade pip
py -m pip install -r requirements.txt
```

Virtual environment example:

```powershell
py -m venv .venv
.venv\Scripts\Activate.ps1
py -m pip install --upgrade pip
py -m pip install -r requirements.txt
```

Packages used by the deploy tooling:

- `tqdm`: progress bars during copy/update
- `pyserial`: serial debug console support
- `hid`: direct USB mode switching for Ethos radios
- `pywin32`: Windows drive detection helpers used by `connect.py`
- `debugpy`: keeps VS Code launch/debug integration happy

## Windows HID Setup

If `hid` installs but radio control still fails, copy the correct `hidapi.dll` for your machine into `C:\Windows\System32`.

Reference package:

- https://github.com/libusb/hidapi/releases/tag/hidapi-0.15.0

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
4. Update `.vscode/settings.json` if you want a different default firmware or language.
5. Adjust the task step list if you do not want `i18n` or `sensors`.

## Folder Conventions

Expected core layout:

```text
vscode-project/
  .vscode/
  src/
    sampleapp/
      main.lua
      i18n/
        en.json
        de.json
  simulator/
```

Optional folders supported by the helper scripts:

- `bin/menu/manifest.source.json`
- `bin/menu/generate.py`
- `bin/sound-generator/soundpack/<lang>/...`
- `.vscode/sensors.json`

If those optional folders do not exist, the helper scripts skip them cleanly.

## Running The Template

Simulator file deploy:

1. Run `Deploy [SIM Files]`.
2. Check `simulator/<firmware>/scripts/<tgt_name>/`.
3. Confirm `simulator/sensors.json` exists after the first simulator deploy.

Simulator launch through VS Code:

1. Make sure the Ethos extension is installed and working.
2. Run `Deploy & Launch [SIM]`.

Radio deploy:

1. Connect the radio over USB.
2. Run `Deploy Radio` or `Deploy Radio [Fast]`.
3. Use `Deploy Radio + Serial Debug` if you want the serial console right after deploy.

Serial-only debug:

1. Run `Radio: Serial Debug`.
2. Stop it with `Ctrl+C`.

## Default Config Files

`.vscode/deploy.json`

```json
{
  "tgt_name": "sampleapp",
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
  "ethos.version": "nightly26",
  "ethosDeployTemplate.deploy.language": "en"
}
```

## Optional Step Scripts

The deploy helpers support these step names:

- `i18n`: resolves `@i18n(...)@` tags using `src/<tgt>/i18n/<lang>.json`
- `sensors`: copies `.vscode/sensors.json` to the simulator root
- `menu`: runs `bin/menu/generate.py` if the menu source exists
- `soundpack`: copies `bin/sound-generator/soundpack/<lang>/...` into the deploy output

Add them in `tasks.json` like this:

```json
"args": [
  "${workspaceFolder}/.vscode/scripts/deploy.py",
  "--lang",
  "${config:ethosDeployTemplate.deploy.language}",
  "--step",
  "i18n",
  "--step",
  "soundpack"
]
```

## Troubleshooting

`Another deploy is already running`

- Run the `Clear locks` task once.

`pyserial not installed`

- Run `py -m pip install pyserial`

`hid module needed`

- Run `py -m pip install hid`

`hidapi.dll is missing`

- Copy the correct `hidapi.dll` into `C:\Windows\System32`

`ethos.start` command not found

- Install or re-enable the Ethos VS Code extension

`Python was not found`

- Install Python 3 for Windows and reopen VS Code
