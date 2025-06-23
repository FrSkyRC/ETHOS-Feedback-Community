-- RB35/35S Base Configure

local translations = {en="RB35(S) config"}

local function name(widget)
  local locale = system.getLocale()
  return translations[locale] or translations["en"]
end

local requestInProgress = false
local refreshIndex = 0
local modifications = {}
local fields = {}
local page = 0
local pages = {"Basic config", "Channel config", "Failsafe config"}
local parameters = {}
local parametersGroup = {}
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

local function createNumberField(line, parameter)
  local field = form.addNumberField(line, nil, parameter[6], parameter[7], function() return getValue(parameter) end, function(value) setValue(parameter, value) end)
  field:enableInstantChange(false)
  if #parameter >= 8 then
    field:decimals(parameter[8])
  end
  if #parameter >= 9 then
    field:suffix(parameter[9])
  end
  field:enable(false)
  return field
end

local function createFailsafeField(line, parameter)
  local rect = form.getFieldSlots(line, {"-Hold-", "-Record current value-", "-Recorded value-"});

  local button1 = form.addTextButton(line, rect[1], "Hold", function()
    local value = 1 * 256
    modifications[#modifications+1] = {parameter[3], value}
    for i = 1, #fields do
      for j = 1, #fields[i] do
        if fields[i][j] then
          fields[i][j]:enable(false)
        end
      end
    end
  end);
  button1:enable(false)

  local button2 = form.addTextButton(line, rect[2], "Record current value", function()
    local value = 1
    modifications[#modifications+1] = {parameter[3], value}
    for i = 1, #fields do
      for j = 1, #fields[i] do
        if fields[i][j] then
          fields[i][j]:enable(false)
        end
      end
    end
  end);
  button2:enable(false)

  local numberEdit = form.addNumberField(line, rect[3], parameter[6], parameter[7], function()
    if parameter[5] == nil then
      return 0
    else
      return math.floor(parameter[5] / 256)
    end
  end, function(value)
    value = value * 256
    modifications[#modifications+1] = {parameter[3], value}
    for i = 1, #fields do
      for j = 1, #fields[i] do
        if fields[i][j] then
          fields[i][j]:enable(false)
        end
      end
    end
  end)
  numberEdit:enableInstantChange(false)
  pcall(function()
    return numberEdit:text(function (value)
      if value == 1 then
        return "Hold"
      elseif value == 0 then
        return "Rec. value"
      else
        return value
      end
    end)
  end)
  if #parameter >= 8 then
    numberEdit:suffix(parameter[8])
  end
  numberEdit:enable(false)

  return {button1, button2, numberEdit}
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

local CHANNEL_CONFIGS = {{"CH1", 0x00}, {"CH2", 0x01}, {"CH3", 0x02}, {"CH4", 0x03}, {"CH5", 0x04}, {"CH6", 0x05}, {"CH7", 0x06}, {"CH8", 0x07},
                         {"CH9", 0x08}, {"CH10", 0x09}, {"CH11", 0x0A}, {"CH12", 0x0B}, {"CH13", 0x0C}, {"CH14", 0x0D}, {"CH15", 0x0E}, {"CH16", 0x0F},
                         {"CH17", 0x10}, {"CH18", 0x11}, {"CH19", 0x12}, {"CH20", 0x13}, {"CH21", 0x14}, {"CH22", 0x15}, {"CH23", 0x16}, {"CH24", 0x17},
                         {"S.Port", 0x40}, {"S.Bus", 0x80}, {"F.Bus", 0xC0}}

local CHANNEL_LOG = {{"CH1", 0x00}, {"CH2", 0x01}, {"CH3", 0x02}, {"CH4", 0x03}, {"CH5", 0x84}, {"CH6", 0x85}, {"CH7", 0x86}, {"CH8", 0x87},
                         {"CH9", 0x88}, {"CH10", 0x89}, {"CH11", 0x8A}, {"CH12", 0x0B}, {"CH13", 0x0C}, {"CH14", 0x0D}, {"CH15", 0x0E}, {"CH16", 0x0F},
                         {"CH17", 0x10}, {"CH18", 0x11}, {"CH19", 0x12}, {"CH20", 0x13}, {"CH21", 0x14}, {"CH22", 0x15}, {"CH23", 0x16}, {"CH24", 0x17}}


local baseParameters = {
  -- { name, type, page, sub, value, min, max }
  {"Physical ID", createNumberField, 0x01, 1, nil, 0, 26 },
  {"Group ID", createNumberField, 0x0D, 1, nil, 0, 15 },
  {"Data rate", createNumberField, 0x22, 1, nil, 1, 10, 1, "s" },
  {"Version", createStaticText, 0x81, 3, nil, 0, 255 },
  {"Current sensor calibrate", createTextButton, 0x80, 3, nil, "Start" },
  {"Calibrate horizontal", createTextButton, 0xA4, 2, nil, "Start" },
  {"Vbec 1", createNumberField, 0x80, 1, nil, 50, 84, 1, "V" },
  {"Vbec 2", createNumberField, 0x80, 2, nil, 50, 84, 1, "V" },
  {"Battery mode", createChoiceField, 0x81, 1, nil, {{"Balance", 0}, {"Slave", 1}}},
  {"Slaver switch voltage thro.", createNumberField, 0x81, 2, nil, 74, 255, 1, "V" },
  {"Log channel", createChoiceField, 0xA4, 3, nil, CHANNEL_LOG },
  {"Signal period", createChoiceField, 0x82, 1, nil, {{"8ms", 0xFF}, {"20ms", 0x00}}},
  {"IMU mode", createChoiceField, 0xA4, 1, nil, {{"Off", 0}, {"Basic", 1}, {"ADV", 2}}},
}

local channelParameters = {
  {"Channel 1", createChoiceField, 0x83, 1, nil, CHANNEL_CONFIGS },
  {"Channel 2", createChoiceField, 0x83, 2, nil, CHANNEL_CONFIGS },
  {"Channel 3", createChoiceField, 0x83, 3, nil, CHANNEL_CONFIGS },
  {"Channel 4", createChoiceField, 0x84, 1, nil, CHANNEL_CONFIGS },
  {"Channel 5", createChoiceField, 0x84, 2, nil, CHANNEL_CONFIGS },
  {"Channel 6", createChoiceField, 0x84, 3, nil, CHANNEL_CONFIGS },
  {"Channel 7", createChoiceField, 0x85, 1, nil, CHANNEL_CONFIGS },
  {"Channel 8", createChoiceField, 0x85, 2, nil, CHANNEL_CONFIGS },
  {"Channel 9", createChoiceField, 0x85, 3, nil, CHANNEL_CONFIGS },
  {"Channel 10", createChoiceField, 0x86, 1, nil, CHANNEL_CONFIGS },
  {"Channel 11", createChoiceField, 0x86, 2, nil, CHANNEL_CONFIGS },
  {"Channel 12", createChoiceField, 0x86, 3, nil, CHANNEL_CONFIGS },
  {"Channel 13", createChoiceField, 0x87, 1, nil, CHANNEL_CONFIGS },
  {"Channel 14", createChoiceField, 0x87, 2, nil, CHANNEL_CONFIGS },
  {"Channel 15", createChoiceField, 0x87, 3, nil, CHANNEL_CONFIGS },
  {"Channel 16", createChoiceField, 0x88, 1, nil, CHANNEL_CONFIGS },
  {"Channel 17", createChoiceField, 0x88, 2, nil, CHANNEL_CONFIGS },
  {"Channel 18", createChoiceField, 0x88, 3, nil, CHANNEL_CONFIGS },
  {"Channel 19", createChoiceField, 0x89, 1, nil, CHANNEL_CONFIGS },
  {"Channel 20", createChoiceField, 0x89, 2, nil, CHANNEL_CONFIGS },
  {"Channel 21", createChoiceField, 0x89, 3, nil, CHANNEL_CONFIGS },
  {"Channel 22", createChoiceField, 0x8A, 1, nil, CHANNEL_CONFIGS },
  {"Channel 23", createChoiceField, 0x8A, 2, nil, CHANNEL_CONFIGS },
  {"Channel 24", createChoiceField, 0x8A, 3, nil, CHANNEL_CONFIGS },
}

local failsafeParameters = {
  {"Failsafe CH1", createFailsafeField, 0x8B, 0, nil, 890, 2110, "us"},
  {"Failsafe CH2", createFailsafeField, 0x8C, 0, nil, 890, 2110, "us" },
  {"Failsafe CH3", createFailsafeField, 0x8D, 0, nil, 890, 2110, "us" },
  {"Failsafe CH4", createFailsafeField, 0x8E, 0, nil, 890, 2110, "us" },
  {"Failsafe CH5", createFailsafeField, 0x8F, 0, nil, 890, 2110, "us" },
  {"Failsafe CH6", createFailsafeField, 0x90, 0, nil, 890, 2110, "us" },
  {"Failsafe CH7", createFailsafeField, 0x91, 0, nil, 890, 2110, "us" },
  {"Failsafe CH8", createFailsafeField, 0x92, 0, nil, 890, 2110, "us" },
  {"Failsafe CH9", createFailsafeField, 0x93, 0, nil, 890, 2110, "us" },
  {"Failsafe CH10", createFailsafeField, 0x94, 0, nil, 890, 2110, "us" },
  {"Failsafe CH11", createFailsafeField, 0x95, 0, nil, 890, 2110, "us" },
  {"Failsafe CH12", createFailsafeField, 0x96, 0, nil, 890, 2110, "us" },
  {"Failsafe CH13", createFailsafeField, 0x97, 0, nil, 890, 2110, "us" },
  {"Failsafe CH14", createFailsafeField, 0x98, 0, nil, 890, 2110, "us" },
  {"Failsafe CH15", createFailsafeField, 0x99, 0, nil, 890, 2110, "us" },
  {"Failsafe CH16", createFailsafeField, 0x9A, 0, nil, 890, 2110, "us" },
  {"Failsafe CH17", createFailsafeField, 0x9B, 0, nil, 890, 2110, "us" },
  {"Failsafe CH18", createFailsafeField, 0x9C, 0, nil, 890, 2110, "us" },
  {"Failsafe CH19", createFailsafeField, 0x9D, 0, nil, 890, 2110, "us" },
  {"Failsafe CH20", createFailsafeField, 0x9E, 0, nil, 890, 2110, "us" },
  {"Failsafe CH21", createFailsafeField, 0x9F, 0, nil, 890, 2110, "us" },
  {"Failsafe CH22", createFailsafeField, 0xA0, 0, nil, 890, 2110, "us" },
  {"Failsafe CH23", createFailsafeField, 0xA1, 0, nil, 890, 2110, "us" },
  {"Failsafe CH24", createFailsafeField, 0xA2, 0, nil, 890, 2110, "us" },
}

local function runPage(step)
  page = page + step
  if page > 3 then
    page = 3
  elseif page < 1 then
    page = 1
  end
  requestInProgress = false
  refreshIndex = 0
  modifications = {}
  fields = {}
  form.clear()
  parameters = parametersGroup[page]

  local line = form.addLine(pages[page])
  form.addStaticText(line, nil, page.."/"..#pages)

  for index = 1, #parameters do
    local parameter = parameters[index]
    local line = form.addLine(parameter[1])
    local field = parameter[2](line, parameter)
    fields[index] = field
  end
end

local function create()
  idle = false
  requestInProgress = false
  refreshIndex = 0
  modifications = {}
  fields = {}
  parametersGroup = {baseParameters, channelParameters, failsafeParameters}
  page = 1

  local sensor = sport.getSensor({appIdStart=0x0F00, appIdEnd=0x0F0F});
  -- print("widget.sensor:appId = ", sensor:appId())

  runPage(0)

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
      if fieldId == parameter[3] then
        value = math.floor(value / 256)
        -- print("widget.sensor:value = ", value)
        while parameters[refreshIndex + 1][3] == fieldId do
          if parameters[refreshIndex + 1][5] ~= nil and value ~= nil then
            lcd.invalidate()
          end
          parameters[refreshIndex + 1][5] = value
          if value ~= nil then
            if fields[refreshIndex + 1] then
              if type(fields[refreshIndex + 1]) == "table" then
                for index = 1, #fields[refreshIndex + 1] do
                  fields[refreshIndex + 1][index]:enable(true)
                end
              else
                fields[refreshIndex + 1]:enable(true)
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
end

local function event(widget, category, value, x, y)
  -- print("Event received:", category, value, x, y, KEY_EXIT_BREAK)
  if category == EVT_KEY and value == KEY_PAGE_UP then
    runPage(-1)
    system.killEvents(KEY_PAGE_DOWN);
    return true
  elseif category == EVT_KEY and value == KEY_PAGE_DOWN then
    runPage(1)
    return true
  else
    return false
  end
end

local function close(widget)
  widget.sensor:idle(false)
end

return {name=name, create=create, wakeup=wakeup, event=event, close=close}
