-- RB35/35S Base Configure

local translations = {en="RB35(S) gyro memory"}

local function name(widget)
  local locale = system.getLocale()
  return translations[locale] or translations["en"]
end

local requestInProgress = false
local refreshIndex = 0
local modifications = {}
local fields = {}
local idle = false

local function getValue(parameter)
  if parameter[5] == nil then
    return 0
  else
    local sub = parameter[4]
    if sub == 0 then
      return math.floor(parameter[5] / 256)
    else
      return ((parameter[5] >> (8 * (sub - 1))) & 0xFF)
    end
  end
end

local function setValue(parameter, value)
  local sub = parameter[4]
  if sub == 0 then
    value = value * 256
  else
    local D1 = parameter[5] & 0xFF
    local D2 = (parameter[5] >> 8) & 0xFF
    local D3 = (parameter[5] >> 16) & 0xFF
    if sub == 1 then
      D1 = value
    elseif sub == 2 then
      D2 = value
    elseif sub == 3 then
      D3 = value
    end
    value = D1 + D2 * 256 + D3 * 256 * 256
  end
  modifications[#modifications+1] = {parameter[3], value}
  for index = 1, #fields do
    if fields[index] then
      fields[index]:enable(false)
    end
  end
end

local groupFieldTextFunc = function(value)
  if value >= 15 then
    return "Preset bank"
  else
    return "Bank " .. (value + 1)
  end
end

local function createGroupField(line, parameter)
  local field = form.addNumberField(line, nil, parameter[6], parameter[7], function() return getValue(parameter) end, function(value) setValue(parameter, value) end)
  field:enableInstantChange(false)
  field:text(groupFieldTextFunc)
  field:enable(false)
  return field
end

local function createCHField(line, parameter)
  local field = form.addNumberField(line, nil, parameter[6], parameter[7], function() return getValue(parameter) end, function(value) setValue(parameter, value) end)
  field:enableInstantChange(false)
  field:text(function(value)
    return "CH " .. (value + 1)
  end)
  field:enable(false)
  return field
end

local function createChoiceField(line, parameter)
  local field = form.addChoiceField(line, nil, parameter[6], function() return getValue(parameter) end, function(value) setValue(parameter, value) end)
  field:enable(false)
  return field
end

local function createTextButton(line, parameter)
  local field = form.addTextButton(line, nil, parameter[6], function() return setValue(parameter, 1) end)
  field:enable(false)
  return field
end

local function createStaticText(line, parameter)
  form.addStaticText(line, nil, tostring(parameter[6]))
  return nil
end

local groupEnableKey = {address = 0xFD, subId = 3}
local groupEnable = false

local parameters = {
  {"Current gyro memory", createGroupField, 0xFD, 1, nil, 0, 15 },
  {"Gyro memory ON/OFF", createChoiceField, 0xFD, 3, nil, { {"OFF", 0x00}, {"ON", 0x01}} },
  {"Gyro memory switch CH.", createCHField, 0xFD, 2, nil, 0, 23 },
  {"G.Mem bank at CH -100%", createGroupField, 0xFB, 1, nil, 0, 15 },
  {"G.Mem bank at CH 0%", createGroupField, 0xFB, 2, nil, 0, 15 },
  {"G.Mem bank at CH 100%", createGroupField, 0xFB, 3, nil, 0, 15 },
}

local button = nil
local fromGroup = 0
local toGroup = 0

local function create()
  idle = false
  requestInProgress = false
  refreshIndex = 0
  modifications = {}
  fields = {}

  local sensor = sport.getSensor({appIdStart=0x0F00, appIdEnd=0x0F0F});

  for index = 1, #parameters do
    local parameter = parameters[index]
    local line = form.addLine(parameter[1])
    local field = parameter[2](line, parameter)
    fields[index] = field
  end

  local panel = form.addExpansionPanel("Copy bank")
  local line = panel:addLine("From")
  local numberField = form.addNumberField(line, nil, 0, 15, function() return fromGroup end, function(newValue) fromGroup = newValue end)
  numberField:text(groupFieldTextFunc)
  line = panel:addLine("To")
  numberField = form.addNumberField(line, nil, 0, 15, function() return toGroup end, function(newValue) toGroup = newValue end)
  numberField:text(groupFieldTextFunc)
  line = panel:addLine("")
  button = form.addTextButton(line, nil, "Copy cfg. bank", function()
    modifications[#modifications+1] = {0xFC, 0x81 + toGroup * 256 + fromGroup * 256 * 256}
  end)
  button:enable(false)

  return {sensor=sensor}
end

local function wakeup(widget)
  local invalidateNeeded = false
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
  if idle == false then
    widget.sensor:idle()
    idle = true
  end
  if requestInProgress then
    local value = widget.sensor:getParameter()
    -- print("widget.sensor:getParameter = ", value)
    if value then
      local fieldId = value % 256
      local parameter = parameters[refreshIndex + 1]
      if groupEnableKey.address == fieldId then
        groupEnable = (value >> (8 * groupEnableKey.subId) == 1)
      end
      if fieldId == parameter[3] then
        value = math.floor(value / 256)
        -- print("widget.sensor:value = ", value)
        while parameters[refreshIndex + 1][3] == fieldId do
          if parameters[refreshIndex + 1][5] ~= nil and value ~= nil then
            invalidateNeeded = true;
          end
          parameters[refreshIndex + 1][5] = value
          if value ~= nil then
            if fields[refreshIndex + 1] then
              if type(fields[refreshIndex + 1]) == "table" then
                for index = 1, #fields[refreshIndex + 1] do
                  fields[refreshIndex + 1][index]:enable(true)
                end
              else
                if refreshIndex < 2 then
                  fields[refreshIndex + 1]:enable(true)
                else
                  fields[refreshIndex + 1]:enable(groupEnable)
                end
              end
              if button ~= nil then
                button:enable(true)
              end
            end
          end
          refreshIndex = refreshIndex + 1
          if refreshIndex > (#parameters - 1) then break end
        end
        requestInProgress = false
      end
    else
      requestInProgress = false
    end
  else
    if #modifications > 0 then
      -- print("writeParameter", modifications[1][1], modifications[1][2])
      if widget.sensor:writeParameter(modifications[1][1], modifications[1][2]) == true then
        if modifications[1][1] == 0x13 then -- appId changed
          widget.sensor:appId(0x0F00 + ((modifications[1][2] >> 8) & 0xFF))
        end
        refreshIndex = 0
        requestInProgress = false
        modifications[1] = nil
      end
    elseif refreshIndex <= (#parameters - 1) then
      local parameter = parameters[refreshIndex + 1]
      -- print("requestParameter", parameter[3])
      if widget.sensor:requestParameter(parameter[3]) then
        requestInProgress = true
      end
    end
  end
  if invalidateNeeded then
    lcd.invalidate()
  end
end

local function close(widget)
  local count = 0;
  while count < 3 do
    if widget.sensor:idle(false) then
      count = count + 1
    end
  end
  idle = false
end

return {name=name, create=create, wakeup=wakeup, close=close}
