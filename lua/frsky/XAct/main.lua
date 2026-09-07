local LUA_VERSION = "2.0.3";

local env = setmetatable({}, { __index = _G })
env._G = env

function env.loadfile(path, mode, givenEnv)
  return _G.loadfile(path, mode, givenEnv or env)
end

local function import(path)
  return assert(env.loadfile(path))()
end

local STR = import("i18n/i18n.lua").translate
env.STR = STR

local function name()
  return STR("ScriptName")
end

local basic = import("basic.lua")

local pages = { basic }

local icon = lcd.loadBitmap("xact.png");

local function init()
  system.registerDeviceConfig({category = DEVICE_CATEGORY_SERVOS, name = name, bitmap = icon, appIdStart = 0x6800, appIdEnd = 0x680F, version = LUA_VERSION, pages = pages})
end

return { init = init }
