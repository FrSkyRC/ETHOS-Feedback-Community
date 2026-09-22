-- Lua sensor example

local function init()
  system.registerSensor({
    appIdStart = 0x5100,               -- first S.Port appId this definition matches
    appIdEnd = 0x510F,                 -- last S.Port appId this definition matches (optional, defaults to appIdStart)
    name = "My sensor",                -- sensor name
    unit = UNIT_KILOMETER_PER_HOUR,    -- sensor unit (UNIT_* constant, optional, defaults to UNIT_NONE)
    decimals = 1,                      -- number of decimals (optional, defaults to 0)
    min = 0.0,                         -- protocol minimum value (optional)
    max = 300.0,                       -- protocol maximum value (optional)
    userMin = 0.0,                     -- user-editable minimum value (optional, defaults to min)
    userMax = 100.0,                   -- user-editable maximum value (optional, defaults to max)
    onDiscover = function(source)      -- called when the sensors Discover creates this sensor
      print(string.format("Hello world! I am sensor appId=0x%04X name=%s", source:appId(), source:name()))
    end
  })
end

return {init=init}
