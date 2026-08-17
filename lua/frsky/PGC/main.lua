local LUA_VERSION = "1.0.3";
local nameI18n = {en = "PGC"}

local function name()
  local locale = system.getLocale()
  return nameI18n[locale] or nameI18n["en"]
end

local basic = assert(loadfile("basic.lua"))()

local pages = { basic }

local icon = lcd.loadBitmap("pgc.png")

local function init()
  if system.registerDeviceConfig ~= nil then
    system.registerDeviceConfig({category = DEVICE_CATEGORY_SENSORS, name = name, bitmap = icon, appIdStart = 0x1040, appIdEnd = 0x104F, version = LUA_VERSION, pages = pages})
  else
    system.registerSystemTool({name = name, icon = icon, create = basic.create, wakeup = basic.wakeup, close = basic.close})
  end
end

return { init = init }
