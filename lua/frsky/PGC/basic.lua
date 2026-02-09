assert(loadfile("config.lua"))()

local parameters = {
  {fieldFunction = CreateNumberField, fieldName = "Landing gear ctrl. ch.", pageAddress = 0x80, defaultValue = 1, extraInfo = {min = 1, max = 24, prefix = "CH"}},
  {fieldFunction = CreateNumberField, fieldName = "Landing gear working volt.", pageAddress = 0x81, defaultValue = 60, extraInfo = {min = 60, max = 120, prec = 1, suffix = "V/bit"}},
  {fieldFunction = CreateNumberField, fieldName = "Door working volt.", pageAddress = 0x82, defaultValue = 60, extraInfo = {min = 60, max = 120, prec = 1, suffix = "V/bit"}},
  {fieldFunction = CreateChoiceField, fieldName = "Aft. door mode", pageAddress = 0x83, defaultValue = 1, extraInfo = {valuePairs = {{"Mode A", 1}, {"Mode B", 2}}}},
  {fieldFunction = CreateChoiceField, fieldName = "Fwd. door mode", pageAddress = 0x93, defaultValue = 1, extraInfo = {valuePairs = {{"Mode A", 1}, {"Mode B", 2}}}},
  {fieldFunction = CreateNumberField, fieldName = "Left landing gear stall cur.", pageAddress = 0x84, defaultValue = 1, extraInfo = {min = 1, max = 50, prec = 1, suffix = "A/bit"}},
  {fieldFunction = CreateNumberField, fieldName = "Right landing gear stall cur.", pageAddress = 0x85, defaultValue = 1, extraInfo = {min = 1, max = 50, prec = 1, suffix = "A/bit"}},
  {fieldFunction = CreateNumberField, fieldName = "Nose landing gear stall cur.", pageAddress = 0x86, defaultValue = 1, extraInfo = {min = 1, max = 50, prec = 1, suffix = "A/bit"}},
  {fieldFunction = CreateChoiceField, fieldName = "Left landing gear INVERT", pageAddress = 0x87, defaultValue = 1, extraInfo = {valuePairs = {{"Off", 1}, {"On", 2}}}},
  {fieldFunction = CreateChoiceField, fieldName = "Right landing gear INVERT", pageAddress = 0x88, defaultValue = 1, extraInfo = {valuePairs = {{"Off", 1}, {"On", 2}}}},
  {fieldFunction = CreateChoiceField, fieldName = "Nose Landing gear INVERT", pageAddress = 0x89, defaultValue = 1, extraInfo = {valuePairs = {{"Off", 1}, {"On", 2}}}},
  {fieldFunction = CreateNumberField, fieldName = "Door speed", pageAddress = 0x8A, defaultValue = 1, extraInfo = {min = 1, max = 10}},
  {fieldFunction = CreateNumberField, fieldName = "Nose door close value", pageAddress = 0x8B, defaultValue = 500, extraInfo = {min = 500, max = 2500}},
  {fieldFunction = CreateNumberField, fieldName = "Nose door open value", pageAddress = 0x8C, defaultValue = 500, extraInfo = {min = 500, max = 2500}},
  {fieldFunction = CreateNumberField, fieldName = "Right door close value", pageAddress = 0x8D, defaultValue = 500, extraInfo = {min = 500, max = 2500}},
  {fieldFunction = CreateNumberField, fieldName = "Right door open value", pageAddress = 0x8E, defaultValue = 500, extraInfo = {min = 500, max = 2500}},
  {fieldFunction = CreateNumberField, fieldName = "Left door close value", pageAddress = 0x8F, defaultValue = 500, extraInfo = {min = 500, max = 2500}},
  {fieldFunction = CreateNumberField, fieldName = "Left door open value", pageAddress = 0x90, defaultValue = 500, extraInfo = {min = 500, max = 2500}},
  {fieldFunction = CreateNumberField, fieldName = "Delay after door open", pageAddress = 0x91, defaultValue = 0, extraInfo = {min = 0, max = 10, suffix = "s"}},
  {fieldFunction = CreateNumberField, fieldName = "Delay before door close", pageAddress = 0x92, defaultValue = 0, extraInfo = {min = 0, max = 10, suffix = "s"}},
  {fieldFunction = CreateNumberField, fieldName = "Brake ctrl. ch.", pageAddress = 0xA0, defaultValue = 1, extraInfo = {min = 1, max = 24, prefix = "CH"}},
  {fieldFunction = CreateNumberField, fieldName = "Brake working volt.", pageAddress = 0xA1, defaultValue = 60, extraInfo = {min = 60, max = 120, prec = 1, suffix = "V/bit"}},
  {fieldFunction = CreateNumberField, fieldName = "Right brake level", pageAddress = 0xA2, defaultValue = 10, extraInfo = {min = 10, max = 100, suffix = "%"}},
  {fieldFunction = CreateNumberField, fieldName = "Left brake level", pageAddress = 0xA3, defaultValue = 10, extraInfo = {min = 10, max = 100, suffix = "%"}},
  {fieldFunction = CreateNumberField, fieldName = "Brake velocity threshold", pageAddress = 0xA4, defaultValue = 5, extraInfo = {min = 4, max = 50, text = function(value) return (value == 4) and ("Off") or ("" .. value / 10) end}},
  {fieldFunction = CreateNumberField, fieldName = "Gear up brake level", pageAddress = 0xA5, extraInfo = {min = 0, max = 50, suffix = "%"}},
  {fieldFunction = CreateNumberField, fieldName = "Brake self-stab weight", pageAddress = 0xA6, extraInfo = {min = 0, max = 30}},
  -- {fieldFunction = CreateChoiceField, fieldName = "Brake self-stab mode", pageAddress = 0x98, defaultValue = 1, extraInfo = {valuePairs = {{"Addition", 1}, {"Subtraction", 2}}}},
  {fieldFunction = CreateNumberField, fieldName = "Steer channel", pageAddress = 0xB0, defaultValue = 1, extraInfo = {min = 1, max = 24, prefix = "CH"}},
  {fieldFunction = CreateNumberField, fieldName = "Steer range", pageAddress = 0xB1, defaultValue = 10, extraInfo = {min = 10, max = 100, suffix = "%"}},
  {fieldFunction = CreateNumberField, fieldName = "Steer stabilizer gain", pageAddress = 0xB2, extraInfo = {min = 0, max = 99, text = function(value) return value == 0 and "Off" or "" .. (value / 10) end}},
  {fieldFunction = CreateChoiceField, fieldName = "Steer stabilizer direction", pageAddress = 0xB3, defaultValue = 1, extraInfo = {valuePairs = {{"Normal", 1}, {"Reverse", 2}}}},
  {fieldFunction = CreateNumberField, fieldName = "Steer trim", pageAddress = 0xB4, defaultValue = 50, extraInfo = {min = 0, max = 100, text = function(value) return (value - 50) .. "%" end}},
}

local function create()
  Params = parameters
  ConfigCreate()
  return {sensor = sport.getSensor({appIdStart = 0x1040, appIdEnd = 0x104F}), needIdle = true}
end

return {create = create, name = "PGC", wakeup = ConfigWakeup, close = ConfigClose}
