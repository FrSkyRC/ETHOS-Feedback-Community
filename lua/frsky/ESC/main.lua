local LUA_VERSION = "1.1.5";
local nameI18n = {en = "ESC"}

local function name()
  local locale = system.getLocale()
  return nameI18n[locale] or nameI18n["en"]
end

local basic = assert(loadfile("basic.lua"))()

local pages = { basic }

local icon = lcd.loadBitmap("esc.png");

local function init()
  system.registerDeviceConfig({category = DEVICE_CATEGORY_ESC, name = name, bitmap = icon, appIdStart = 0x0B50, appIdEnd = 0x0B7F, version = LUA_VERSION, pages = pages})
end

return { init = init }
