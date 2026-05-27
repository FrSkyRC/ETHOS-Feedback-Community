# FrSky ETHOS: Local Lua Script Package Specification V1 (`ethos_lua_manifest.json`)

This document explains how to prepare a ETHOS Lua script ZIP package that can be correctly recognized and installed via **Lua Library -> Install from local `.zip`** into the radio path `RADIO:/scripts/{folder}/`.

## Overview

- Package format: **ZIP**
- A root-level `ethos_lua_manifest.json` is required in the ZIP (case-insensitive filename), Ethos Suite installs **strictly by manifest**: it copies only paths resolved from `files` and writes an installed `ethos_lua_manifest.json` into the target script directory. **If `ethos_lua_manifest.json` exists but is invalid, installation fails.**

Using a valid `ethos_lua_manifest.json` is strongly recommended for all third-party developers so script identity, versioning, and install scope are predictable.

## `ethos_lua_manifest.json` Fields (`manifestVersion = 1`)

| Field | Type | Required | Description |
|------|------|------|------|
| `manifestVersion` | number | Yes | Must be **1**. Future format changes will use newer versions. |
| `name` | string | Yes | Display name of the script, max 128 chars. |
| `key` | string | Yes | Global stable unique ID (reverse-domain style recommended, e.g. `com.example.mywidget`). Allowed chars: letters, digits, `.`, `_`, `:`, `-`; length 1-128; must start with a letter or digit. Used for script identity and upgrade matching. |
| `version` | string | Yes | Version string that can be parsed as numeric 3-part version (e.g. `1.0.0`, `01.02.03`). |
| `introduction` | string | No | One sentence introduction for the script, max 1024 chars. |
| `releaseNotes` | string \| object | No | Release notes. Two forms are supported: (1) string (default rendered as markdown), (2) object `{ "format": "markdown" \| "text", "content": "..." }`. `content` max length is 32000 chars. |
| `folder` | string | Yes | Install directory under `SCRIPTS:` (`RADIO:/scripts/{folder}/`). Length 1-64, must start with letter/digit, allowed chars: `a-z`, `A-Z`, `0-9`, `.`, `_`, `-`. |
| `files` | string[] | Yes | File selector array. Supports: (1) exact file path (`main.lua`), (2) single-level wildcard (`i18n/*`), (3) recursive wildcard (`assets/**`). Use `/` separators. `..`, absolute paths, and empty segments are forbidden. After expansion, at least one file must exist and it must include **`main.lua`** or **`main.luac`**. |

`ethos_lua_manifest.json` itself does **not** need to be listed in `files`. If listed, it is ignored and will not be copied.

## Path and Security Rules

- All paths are relative to ZIP root, e.g. `lib/helper.lua`, `i18n/en.txt`.
- Forbidden: `../`, `..`, absolute paths starting with `/`, drive-letter absolute paths.
- ZIP entry matching uses normalized forward slashes and is case-insensitive.
- `folder` and ZIP internal structure are **independent**: `folder` defines install root `RADIO:/scripts/{folder}/`, while selected relative paths from `files` are preserved under that root.

### Case: `folder=A` but ZIP root only contains `B/`

Given:

- `folder = "A"`
- ZIP root contains `B/...` and `ethos_lua_manifest.json`
- `files = ["B/**"]`

Install result:

- `RADIO:/scripts/A/B/...`

not:

- `RADIO:/scripts/A/...`

Current spec does **not** support stripping the outer directory (e.g. `B`) automatically. If you want files directly under `A`, either:

1. Repackage so script files are placed at ZIP root and point `files` to root paths;
2. List exact source paths in `files` to match desired layout (not ideal for large packages).

## Minimal Example

ZIP contents:

```text
ethos_lua_manifest.json
main.lua
README.txt
```

`ethos_lua_manifest.json`:

```json
{
  "manifestVersion": 1,
  "name": "Demo Script",
  "key": "com.example.demoscript",
  "version": "1.0.0",
  "releaseNotes": {
    "format": "markdown",
    "content": "## v1.0.0\n\n- First public release\n- Basic page support"
  },
  "folder": "DemoScript",
  "files": [
    "main.lua",
    "README.txt"
  ]
}
```

Install result:

- `RADIO:/scripts/DemoScript/main.lua`
- `RADIO:/scripts/DemoScript/README.txt`
- `RADIO:/scripts/DemoScript/ethos_lua_manifest.json` (auto-generated/updated by Suite, includes fields like `name`, `key`, `version`, `files`)

## Example with Subdirectories

ZIP contents:

```text
ethos_lua_manifest.json
main.lua
widgets/chart.lua
bitmaps/icon.png
```

`ethos_lua_manifest.json` (`files`):

```json
{
  "manifestVersion": 1,
  "name": "Chart Widget",
  "key": "org.ethos.chartwidget",
  "version": "1.2.0",
  "folder": "ChartWidget",
  "files": [
    "main.lua",
    "widgets/*",
    "bitmaps/**"
  ]
}
```

## `releaseNotes` Display Behavior

- For locally installed scripts, if the installed `ethos_lua_manifest.json` contains `releaseNotes`, it will be shown:
  - `releaseNotesFormat = "markdown"`: rendered as Markdown
  - `releaseNotesFormat = "text"`: shown as plain text
- If no script info is available, the app shows a fallback message.

## Developer Checklist

1. ZIP root includes **`ethos_lua_manifest.json`** (UTF-8 recommended).
2. `manifestVersion` is **1**.
3. `key` is unique and stable across releases.
4. `version` is incremented per release.
5. `folder` does not unintentionally conflict with existing script directories.
6. `files` covers all required files and includes `main.lua` or `main.luac`.
7. Test installation locally through Ethos Suite and verify behavior on radio.

## Relationship with Installed Metadata

After installation, Suite writes `ethos_lua_manifest.json` under `{folder}/` as the installed metadata file. `key`, `version`, `name`, `releaseNotes`, and `files` are preserved for local management. During updates, old files can be removed based on previous installed `files` entries before new files are copied.

The existing legacy `scriptinfo.json` won't be read any more.
