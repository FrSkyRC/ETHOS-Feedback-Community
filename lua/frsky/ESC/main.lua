-- FrSky ESC Configure

local translations = {en="FrSky ESC"}

local function name(widget)
  local locale = system.getLocale()
  return translations[locale] or translations["en"]
end

local requestInProgress = false
local refreshIndex = 0
local modifications = {}
local repeatTimes = 0
local requestTime = 0
local fields = {}
local idle = false
local appId = 0

local function getValue(parameter)
  if parameter[4] == nil then
    return 0
  else
    return parameter[4]
  end
end

local function setValue(parameter, value)
  parameter[4] = value
  if parameter[3] == 0x89 then
    value = value * 100
  elseif parameter[3] == 0x8A then
    value = value * 10
  end
  local mValue = (value & 0xFF) * 256 + ((value >> 8) & 0xFF)
  modifications[#modifications+1] = {parameter[3], mValue}
  for index = 1, #fields do
    if fields[index] then
      fields[index]:enable(false)
    end
  end
end

local function createNumberField(line, parameter)
  local field = form.addNumberField(line, nil, parameter[5], parameter[6], function() return getValue(parameter) end, function(value) setValue(parameter, value) end)
  field:enableInstantChange(false)
  if #parameter == 8 then
    field:decimals(parameter[8])
  end
  if #parameter >= 7 then
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

local parameters = {
  -- { name, type, page, sub, value, min, max }
  {"Rotation Direction",  createChoiceField, 0x80, 0, {{"Normal", 0}, {"Reversed", 1}}},
  {"Use Sin Start",       createChoiceField, 0x81, 1, {{"OFF", 0}, {"ON", 1}}},
  {"Soft Start",          createChoiceField, 0x82, 0, {{"OFF", 0}, {"ON", 1}}},
  {"ESC Beep",            createChoiceField, 0x83, 1, {{"OFF", 0}, {"ON", 1}}},
  {"PWM Min(Effective after restart)",       createNumberField, 0x84, 1000, 885, 1500},
  {"PWM Max(Effective after restart)",       createNumberField, 0x85, 2000, 1500, 2115},
  {"Soft Brake",          createNumberField, 0x86, 0, 0, 100, "%"},
  {"3D Mode(Effective after restart)",       createChoiceField, 0x87, 0, {{"OFF", 0}, {"ON", 1}}},
  {"Current Calibration", createNumberField, 0x88, 100, 75, 125, "%", 0},
  {"Current Limit",       createNumberField, 0x89, 40, 0, 655, "A"},
  {"BEC Voltage",         createNumberField, 0x8A, 50, 50, 84, "V", 1},
  {"Trapezoidal Mode",    createChoiceField, 0x8B, 0, {{"OFF", 0}, {"ON", 1}}},
  {"Phy Id",              createNumberField, 0x8C, 10, 0, 26},
  {"App Group Id",        createNumberField, 0x8D, 0, 0, 15},
  {"Time Gap",            createNumberField, 0x8E, 10, 0, 255, "00ms"},
  {"Motor Pole Count",    createNumberField, 0x8F, 14, 2, 255},
  {"FBus Thr CH(Effective after restart)",   createNumberField, 0x90, 1, 1, 255},
  {"High Demag prot",    createChoiceField, 0x91, 0, {{"OFF", 0}, {"ON", 1}}},
}

local function updateField(index)
  if parameters[index][4] ~= nil then
    fields[index]:enable(true)
  end
end

local function create()
  print("create()")
  requestInProgress = false
  refreshIndex = 0
  modifications = {}
  repeatTimes = 0
  fields = {}
  idle = false

  local sensor = sport.getSensor({appIdStart=0x0E50, appIdEnd=0x0E5F});

  for index = 1, #parameters do
    local parameter = parameters[index]
    local line = form.addLine(parameter[1])
    local field = parameter[2](line, parameter)
    fields[#fields + 1] = field
  end

  return {sensor=sensor}
end

local function wakeup(widget)
  if widget.sensor:alive() then
    if idle == false then
      appId = widget.sensor:appId()
      widget.sensor:idle()
      idle = true
    end
    if requestInProgress then
      local value = widget.sensor:getParameter()
      local parameter = parameters[refreshIndex + 1]
      if value then
        local fieldId = value % 256
        if fieldId == parameter[3] then
          value = math.floor(value / 256)
          if parameter[3] == 0x89 then
            parameter[4] = value / 100
          elseif parameter[3] == 0x8A then
            parameter[4] = value / 10
          else
            parameter[4] = value
          end
          if value ~= nil then
            if fields[refreshIndex + 1] then
              fields[refreshIndex + 1]:enable(true)
            end
          end
          refreshIndex = refreshIndex + 1
          requestInProgress = false
        end
      elseif requestTime < os.time() + 5 then --5s
        requestInProgress = false
      end
    else
      if #modifications > 0 then
        if widget.sensor:writeParameter(modifications[1][1], modifications[1][2]) == true then
          if modifications[1][1] == 0x8D then -- appId changed
            appId = 0x0E50 + ((modifications[1][2] >> 8) & 0xFF)
            widget.sensor:appId(appId)
          end
          refreshIndex = 0
          requestInProgress = false
          modifications[1] = nil
        end
      elseif refreshIndex <= (#parameters - 1) then
        local parameter = parameters[refreshIndex + 1]
        if widget.sensor:requestParameter(parameter[3]) then
          requestInProgress = true
          requestTime = os.time()
        end
      end
    end
  end
end

local function event(widget, category, value, x, y)
  if category == EVT_KEY and (value == KEY_EXIT_BREAK or value == KEY_EXIT_LONG) then
    widget.sensor:idle(false)
  end
  return false
end

local function close(widget)
  widget.sensor:idle(false)
end

local icon = lcd.loadMask("esc.png")

local function init()
  system.registerSystemTool({name=name, icon=icon, create=create, wakeup=wakeup, event=event, close=close})
end

return {init=init}
