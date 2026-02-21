--=============================================================================
--  ethos_events.lua
--
--  Ethos Event Debug Helper
--
--  PURPOSE
--  -------
--  Converts Ethos event category/value numbers into readable names by
--  scanning runtime constants (EVT_*, KEY_*, TOUCH_*, ROTARY_*), and
--  prints formatted debug output (or returns the formatted line).
--
--  Designed for:
--    • Widgets
--    • Tools
--    • Model scripts
--    • Quick event inspection while developing
--
--  INSTALLATION
--  ------------
--  Place this file in:
--      /SCRIPTS/LIB/ethos_events.lua
--
--  Then include it in your script:
--
--      local events = require("ethos_events")
--
--
--  BASIC USAGE
--  -----------
--  Inside your event handler:
--
--      function dashboard.event(widget, category, value, x, y)
--          events.debug("dashboard", category, value, x, y)
--      end
--
--
--  OUTPUT FORMAT
--  -------------
--      [tag] CATEGORY  VALUE  x=... y=...
--
--  Example:
--      [dashboard] EVT_KEY (1)  KEY_PAGE_LONG (128)  x=nil y=nil
--
--
--  OPTIONAL FILTERING
--  -------------------
--  events.debug(tag, category, value, x, y, options)
--
--  options table supports:
--
--      onlyKey = true
--          → Only print EVT_KEY events
--
--      onlyValues = { [KEY_*]=true }
--          → Only print selected key values
--
--      throttleSame = true
--          → Suppress identical consecutive lines
--
--      returnOnly = true
--          → Return the formatted line instead of printing it
--
--
--  EXAMPLE: Only PAGE Keys
--
--      local only = {
--          [KEY_PAGE_LONG]  = true,
--          [KEY_PAGE_FIRST] = true,
--          [KEY_PAGE_UP]    = true,
--          [KEY_PAGE_BREAK] = true,
--          [KEY_PAGE_DOWN]  = true,
--      }
--
--      events.debug("dashboard", category, value, x, y,
--          { onlyValues = only, throttleSame = true })
--
--
--  NOTES
--  -----
--  • Safe to include in production; simply remove debug() calls.
--  • If a constant isn't found at runtime, its numeric value will be printed.
--
--=============================================================================

local M = {}

-- ---------------------------------------------------------------------------
-- Event/Key/Touch names (runtime scan)
-- ---------------------------------------------------------------------------

local EVT_NAMES = {}
local KEY_NAMES = {}
local TOUCH_NAMES = {}

-- Add any KEY_*/TOUCH_*/EVT_* constants exposed in the environment.
for k, v in pairs(_G) do
  if type(v) == "number" then
    if (k:match("^KEY_") or k:match("^ROTARY_")) and KEY_NAMES[v] == nil then
      KEY_NAMES[v] = k
    elseif k:match("^TOUCH_") and TOUCH_NAMES[v] == nil then
      TOUCH_NAMES[v] = k
    elseif k:match("^EVT_") and EVT_NAMES[v] == nil then
      EVT_NAMES[v] = k
    end
  end
end

-- ---------------------------------------------------------------------------
-- Internal helpers
-- ---------------------------------------------------------------------------

local function nameOrNumber(map, n)
  if n == nil then return "nil" end
  return map[n] or tostring(n)
end

local function nameWithNumber(map, n)
  if n == nil then return "nil" end
  local name = map[n]
  if name then
    return string.format("%s (%s)", name, tostring(n))
  end
  return tostring(n)
end

local lastLine = nil

-- ---------------------------------------------------------------------------
-- Public debug function
-- ---------------------------------------------------------------------------

function M.debug(tag, category, value, x, y, options)
  options = options or {}

  if options.onlyKey and category ~= EVT_KEY then
    return
  end

  if options.onlyValues and not options.onlyValues[value] then
    return
  end

  local catName = nameWithNumber(EVT_NAMES, category)

  local valName
  if category == EVT_KEY then
    valName = nameWithNumber(KEY_NAMES, value)
  elseif category == EVT_TOUCH then
    valName = nameWithNumber(TOUCH_NAMES, value)
  else
    valName = tostring(value)
  end

  local line = string.format(
    "[%s] %s  %s  x=%s y=%s",
    tag or "event",
    catName,
    valName,
    tostring(x),
    tostring(y)
  )

  if options.throttleSame and line == lastLine then
    return nil
  end

  lastLine = line
  if not options.returnOnly then
    print(line)
  end
  return line
end

return M
