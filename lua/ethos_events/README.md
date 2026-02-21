# Ethos Events Helper

This folder contains `ethos_events.lua`, a small helper that converts Ethos event
category/value numbers into readable constant names (and still shows the numeric
value). It scans runtime constants (`EVT_*`, `KEY_*`, `TOUCH_*`, `ROTARY_*`) so
new events appear automatically.

## Install

Copy `ethos_events.lua` to your radio:

```
/SCRIPTS/LIB/ethos_events.lua
```

## Usage

```lua
local events = require("ethos_events")

function mytool.event(widget, category, value, x, y)
    events.debug("mytool", category, value, x, y)
end
```

### Return-only mode

If you want the formatted line without printing:

```lua
local line = events.debug("mytool", category, value, x, y, {returnOnly = true})
```

## Example

See `example.lua` in this folder for a minimal system tool using the helper.
