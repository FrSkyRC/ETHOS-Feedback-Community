-- System / Angle sensor: SkyRC SAM-020 angle sensors

local lazy = assert(loadfile("SCRIPTS:/shared/lazy.lua"))()
local icon = lcd.loadMask("angle-sensor.png")

local tool = lazy.wrap({
  name = "Angle sensor",
  icon = icon,
}, "angle-sensor.lua", {"create", "wakeup", "paint", "close"}, true)

local function init()
  system.registerSystemTool(tool)
end

return {init = init}
