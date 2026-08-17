local LUA_VERSION = "2.0.1";
local nameI18n = {en = "XAct"}

local function name()
  local locale = system.getLocale()
  return nameI18n[locale] or nameI18n["en"]
end

local basic = assert(loadfile("basic.lua"))()

local pages = { basic }

local icon = lcd.loadBitmap("xact.png");

local function init()
  system.registerDeviceConfig({category = DEVICE_CATEGORY_SERVOS, name = name, bitmap = icon, appIdStart = 0x6800, appIdEnd = 0x680F, version = LUA_VERSION, pages = pages})
end

return { init = init }
