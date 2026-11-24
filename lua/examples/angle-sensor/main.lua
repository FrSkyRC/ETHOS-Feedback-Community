-- System / Angle sensor: SkyRC SAM-020 angle sensors

local lazy = assert(loadfile("SCRIPTS:/shared/lazy.lua"))()
local icon = lcd.loadMask("angle-sensor.png")

local tool = lazy.wrap({
  name = "Angle sensor",
  icon = icon,
}, "angle-sensor.lua", {"create", "wakeup", "event", "paint", "close"}, true)

-- Also given to Ethos, for the tools which measure an angle (Balance channels)
local angleSensor = {
  name = "SAM-020",
  -- advertises as "SAM20-xxxx" and its Bluetooth address starts with DC:23:4F:C7
  detect = function(device)
    return device.name:sub(1, 6) == "SAM20-" or device.address:upper():sub(1, 11) == "DC:23:4F:C7"
  end,
  read = function(connection)
    connection:read("FFE1")
  end,
  -- the angle in tenths of degree, signed on 16 bits
  readResponse = function(connection, uuid, data)
    if #data >= 2 then
      local raw = string.unpack(">I2", data)
      return (raw > 1800 and raw - 3600 or raw) / 10
    end
  end
}

local function init()
  system.registerSystemTool(tool)
  system.registerAngleSensor(angleSensor)
end

return {init = init}
