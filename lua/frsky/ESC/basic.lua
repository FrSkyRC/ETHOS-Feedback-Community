PROTOCOL_NAME = "protocol_sport"
assert(loadfile("config/config.lua"))()

local valueWrite = function (value)
  return (value & 0xFF) * 256 + ((value >> 8) & 0xFF)
end

local escAppIdPairs = {{"0E50", 0}, {"0E51", 1}, {"0E52", 2}, {"0E53", 3}, {"0E54", 4}, {"0E55", 5}, {"0E56", 6}, {"0E57", 7},
                        {"0E58", 8}, {"0E59", 9}, {"0E5A", 10}, {"0E5B", 11}, {"0E5C", 12}, {"0E5D", 13}, {"0E5E", 14}, {"0E5F", 15},}
               
local parameters = {
  { fieldFunction = CreateChoiceField, fieldName = "Rotation direction", pageAddress = 0x80, valueWrite = valueWrite, extraInfo = {valuePairs = {{"Normal", 0}, {"Reversed", 1}}} },
  { fieldFunction = CreateChoiceField, fieldName = "Use sin start", pageAddress = 0x81, defaultValue = 1, valueWrite = valueWrite, extraInfo = {valuePairs = {{"OFF", 0}, {"ON", 1}}} },
  { fieldFunction = CreateChoiceField, fieldName = "Soft Start", pageAddress = 0x82, valueWrite = valueWrite, extraInfo = {valuePairs = {{"OFF", 0}, {"ON", 1}}} },
  { fieldFunction = CreateChoiceField, fieldName = "ESC beep", pageAddress = 0x83, defaultValue = 1, valueWrite = valueWrite, extraInfo = {valuePairs = {{"OFF", 0}, {"ON", 1}}} },
  { fieldFunction = CreateNumberField, fieldName = "PWM min(Effective after restart)", pageAddress = 0x84, defaultValue = 1000, valueWrite = valueWrite, extraInfo = {min = 885, max = 1500}},
  { fieldFunction = CreateNumberField, fieldName = "PWM max(Effective after restart)", pageAddress = 0x85, defaultValue = 2000, valueWrite = valueWrite, extraInfo = {min = 1500, max = 2115}},
  { fieldFunction = CreateNumberField, fieldName = "Soft brake", pageAddress = 0x86, valueWrite = valueWrite, extraInfo = {min = 0, max = 100, suffix = "%"}},
  { fieldFunction = CreateChoiceField, fieldName = "3D Mode(Effective after restart)", pageAddress = 0x87, valueWrite = valueWrite, extraInfo = {valuePairs = {{"OFF", 0}, {"ON", 1}}} },
  { fieldFunction = CreateNumberField, fieldName = "Current calibration", pageAddress = 0x88, defaultValue = 100, valueWrite = valueWrite, extraInfo = {min = 75, max = 125, suffix = "%"}},
  { fieldFunction = CreateNumberField, fieldName = "Current limit", pageAddress = 0x89, defaultValue = 40, getValue = function (value)
    return value // 100
  end, setValue = function(param, newValue)
    param.value = newValue * 100
    param.state = FieldState.DIRTY
  end, valueWrite = valueWrite, extraInfo = {min = 0, max = 65, suffix = "A"}},
  { fieldFunction = CreateNumberField, fieldName = "BEC voltage", pageAddress = 0x8A, defaultValue = 50, getValue = function (value)
    return value // 10
  end, setValue = function(param, newValue)
    param.value = newValue * 10
    param.state = FieldState.DIRTY
  end, valueWrite = valueWrite, extraInfo = {min = 50, max = 84, suffix = "V", prec = 1, defaultStep = 1}},
  { fieldFunction = CreateChoiceField, fieldName = "Trapezoidal mode", pageAddress = 0x8B, valueWrite = valueWrite, extraInfo = {valuePairs = {{"OFF", 0}, {"ON", 1}}} },
  { fieldFunction = CreatePhyIdField, fieldName = "Physical Id", pageAddress = 0x8C, defaultValue = 10, valueWrite = valueWrite, extraInfo = {} },
  { fieldFunction = CreateAppIdField, fieldName = "Application Id", pageAddress = 0x8D, valueWrite = valueWrite, extraInfo = {valuePairs = escAppIdPairs} },
  { fieldFunction = CreateNumberField, fieldName = "Data rate", pageAddress = 0x8E, defaultValue = 1, valueWrite = valueWrite, extraInfo = {min = 0, max = 10, suffix = "00ms"}},
  { fieldFunction = CreateNumberField, fieldName = "Motor pole count", pageAddress = 0x8F, defaultValue = 14, valueWrite = valueWrite, extraInfo = {min = 2, max = 255}},
  { fieldFunction = CreateNumberField, fieldName = "F.Bus thr. CH(Effective after restart)", pageAddress = 0x90, defaultValue = 1, valueWrite = valueWrite, extraInfo = {min = 1, max = 255}},
  { fieldFunction = CreateChoiceField, fieldName = "High demag prot.", pageAddress = 0x91, valueWrite = valueWrite, extraInfo = {valuePairs = {{"OFF", 0}, {"ON", 1}}} },
}

local function create(module, appId)
  local appRange = {appIdStart = 0x0E50, appIdEnd = 0x0E5F, module = 0xFFFF}
  local sensor = sport.getSensor(appRange)

  BuildConnectionChoice(appRange)

  Params = parameters
  ConfigCreate()

  if appId and appId ~= 0xFFFF then
    print("Receive appId from ETHOS: ", string.format("%04X", appId))
    sensor:appId(appId)
    ConnectedAppId = appId
  end
  if module and module ~= 0xFF then
    print("Receive module from ETHOS: ", module)
    sensor:module(module)
  end

  return {sensor = sensor, needIdle = true}
end

return {create = create, name = "ESC", wakeup = ConfigWakeup, close = ConfigClose}
