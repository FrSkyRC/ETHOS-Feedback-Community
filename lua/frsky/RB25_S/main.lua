local LUA_VERSION = "2.1.3";

local translations = {en="RB25/25S Config"}

local basic = assert(loadfile("basic/basic.lua"))()
local stab = assert(loadfile("stab/stab.lua"))()
local cali = assert(loadfile("cali/cali.lua"))()

local pages = { {name = basic.name, create = basic.create, wakeup = basic.wakeup, event = basic.event, close = basic.close},
                {name = stab.name, create = stab.create, wakeup = stab.wakeup, event = stab.event, close = stab.close},
                {name = cali.name, create = cali.create, paint = cali.paint, wakeup = cali.wakeup, event = cali.event, close = cali.close} }

local function name(widget)
  local locale = system.getLocale()
  return translations[locale] or translations["en"]
end

local icon = lcd.loadMask("rb25.png")

local function init()
  system.registerDeviceConfig({category = DEVICE_CATEGORY_FLIGHT_SAFE, name = name, bitmap = icon, appIdStart = 0xF10, appIdEnd = 0xF1F, version = LUA_VERSION, pages = pages})
end

return { init = init }
