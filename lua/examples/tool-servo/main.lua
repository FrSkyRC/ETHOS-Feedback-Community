-- Lua Servo Configure

local translations = {en="Lua Servo"}

local function name(widget)
  local locale = system.getLocale()
  return translations[locale] or translations["en"]
end

local requestInProgress = false
local refreshIndex = 0
local modifications = {}
local repeatTimes = 0
local fields = {}

local function getValue(parameter)
  if parameter[4] == nil then
    return 0
  else
    return parameter[4]
  end
end

local function setValue(parameter, value)
  parameter[4] = value
  modifications[#modifications+1] = {parameter[3], value}
  for index = 1, #fields do
    fields[index]:enable(false)
  end
end

local function createNumberField(line, parameter)
  local field = form.addNumberField(line, nil, parameter[5], parameter[6], function() return getValue(parameter) end, function(value) setValue(parameter, value) end)
  field:enableInstantChange(false)
  if #parameter == 7 then
    field:suffix(parameter[7])
  end
  field:enable(false)
  return field
end

local function createChoiceField(line, parameter)
  local field = form.addChoiceField(line, nil, parameter[5], function() return getValue(parameter) end, function(value) setValue(parameter, value) end)
  field:enable(false)
  return field
end

local function createChannelField(line, parameter)
  local field = form.addNumberField(line, nil, parameter[5], parameter[6], function() return getValue(parameter) + 1 end, function(value) setValue(parameter, value - 1) end)
  field:prefix("CH")
  field:enableInstantChange(false)
  field:enable(false)
  return field
end

local function createTextButton(line, parameter)
  local field = form.addTextButton(line, nil, parameter[5], function() return setValue(parameter, 0) end)
  field:enable(false)
  return field
end

local parameters = {
  -- { name, type, default, value, min, max }
  {"Physical ID", createNumberField, 0x00, nil, 0, 26 },
  {"Servo ID", createNumberField, 0x01, nil, 0, 15 },
  {"Refresh timer", createNumberField, 0x02, nil, 0, 65535, "ms" },
  {"Range", createChoiceField, 0x04, nil, {{"120°", 0}, {"90°", 1}, {"180°", 2}}},
  {"Direction", createChoiceField, 0x05, nil, {{"CW", 0}, {"CCW", 1}}},
  {"PWM pulse type", createChoiceField, 0x06, nil, {{"1500us", 0}, {"760us", 1}}},
  {"S.Port channel", createChannelField, 0x07, nil, 0, 23 },
  {"Center", createNumberField, 0x08, nil, -125, 125 },
  {"", createTextButton, 0x30, nil, "Save to flash"},
}

local function updateField(index)
  if parameters[index][4] ~= nil then
    fields[index]:enable(true)
  end
end

local function create()
  requestInProgress = false
  refreshIndex = 0
  modifications = {}
  repeatTimes = 0
  fields = {}

  local sensor = sport.getSensor({appIdStart=0x6800, appIdEnd=0x680F});

  for index = 1, #parameters do
    local parameter = parameters[index]
    local line = form.addLine(parameter[1])
    local field = parameter[2](line, parameter)
    fields[#fields + 1] = field
  end

  sensor:idle()

  return {sensor=sensor}
end

local function wakeup(widget)
  -- TODO call discover
  if widget.sensor:appId() == 0xFFFF then
    local frame = widget.sensor:popFrame()
    if frame == nil then
      return
    end
    widget.sensor:module(frame:module())
    widget.sensor:band(frame:band())
    widget.sensor:rx(frame:rx())
    widget.sensor:appId(frame:appId())
  end
  if requestInProgress then
    local value = widget.sensor:getParameter()
    if value then
      local fieldId = value % 256
      local parameter = parameters[refreshIndex + 1]
      if fieldId == parameter[3] then
        value = math.floor(value / 256)
        if parameter[3] == 0x08 then
          value = value & 0xFF;
          if value > parameter[6] then
            value = value - 256
          end
        end

        parameters[refreshIndex + 1][4] = value
        if value ~= nil then
          fields[refreshIndex + 1]:enable(true)
          if refreshIndex + 2 == #parameters then
            fields[#parameters]:enable(true)
          end
        end

        refreshIndex = refreshIndex + 1
        requestInProgress = false
      end
    else
      requestInProgress = false
    end
  else
    if #modifications > 0 then
      if widget.sensor:writeParameter(modifications[1][1], modifications[1][2]) == true then
        if modifications[1][1] == 0x01 then -- appId changed
          widget.sensor:appId(0x6800 + modifications[1][2])
        end
        refreshIndex = 0
        requestInProgress = false
        modifications[1] = nil
      end
    elseif refreshIndex < (#parameters - 1) then
      local parameter = parameters[refreshIndex + 1]
      if widget.sensor:requestParameter(parameter[3]) then
        requestInProgress = true
      end
    end
  end
end

local function event(widget, category, value, x, y)
  print("Event received:", category, value, x, y, KEY_EXIT_BREAK)
  if category == EVT_KEY and value == KEY_EXIT_BREAK then
    widget.sensor:idle(false)
  end
  return false
end

local icon = lcd.loadMask("servo.png")

local function init()
  system.registerSystemTool({name=name, icon=icon, create=create, wakeup=wakeup, event=event})
end

return {init=init}
