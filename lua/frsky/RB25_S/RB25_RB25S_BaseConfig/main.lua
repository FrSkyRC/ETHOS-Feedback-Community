-- RB25/25S Base Configure

local translations = {en="RB25/25S Config"}

local function name(widget)
  local locale = system.getLocale()
  return translations[locale] or translations["en"]
end

local requestInProgress = false
local refreshIndex = 0
local modifications = {}
local repeatTimes = 0
local fields = {}
local page = 0
local pages = {"Base Config", "Channel Config", "Failsafe Config"}
local parameters = {}

local function getValue(parameter)
  if parameter[5] == nil then
    return 0
  else
    local sub = parameter[4]
    return ((parameter[5] >> (8 * (sub - 1))) & 0xFF)
  end
end

local function setValue(parameter, value)
  local sub = parameter[4]
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
  if #parameter == 8 then
    field:suffix(parameter[8])
  end
  field:enable(false)
  return field
end

local function createChoiceField(line, parameter)
  local field = form.addChoiceField(line, nil, parameter[6], function() return getValue(parameter) end, function(value) setValue(parameter, value) end)
  field:enable(false)
  return field
end

local function createChannelField(line, parameter)
  local field = form.addNumberField(line, nil, parameter[6], parameter[7], function() return getValue(parameter) + 1 end, function(value) setValue(parameter, value - 1) end)
  field:prefix("CH")
  field:enableInstantChange(false)
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
                         {"SPORT", 0x40}, {"SBUS", 0x80}, {"FBUS", 0xC0}}

local baseParameters = {
  -- { name, type, page, sub, value, min, max }
  {"Current Sensor Calibrate", createTextButton, 0x00, 3, nil, "Start"},
  {"Software Version", createStaticText, 0x01, 3, nil, 0, 255 },
  {"PWM Frame Rate", createChoiceField, 0x02, 1, nil, {{"8ms", 0x10}, {"20ms", 0x00}}},
  {"Phy ID",        createNumberField, 0x13, 1, nil, 0, 26 },
  {"App ID Group",  createNumberField, 0x13, 2, nil, 0, 15 },
  {"Stabilizer Mode",  createChoiceField, 0x14, 1, nil, {{"OFF", 0x00}, {"BASIC", 0x01},{"ADV",0x02}}},
  {"CaliHorizontal", createChoiceField, 0x14, 2, nil, {{"Disable", 0}, {"Enable", 1}} },
}

local channelParameters = {
  {"Channel 1", createChoiceField, 0x03, 1, nil, CHANNEL_CONFIGS },
  {"Channel 2", createChoiceField, 0x03, 2, nil, CHANNEL_CONFIGS },
  {"Channel 3", createChoiceField, 0x03, 3, nil, CHANNEL_CONFIGS },
  {"Channel 4", createChoiceField, 0x04, 1, nil, CHANNEL_CONFIGS },
  {"Channel 5", createChoiceField, 0x04, 2, nil, CHANNEL_CONFIGS },
  {"Channel 6", createChoiceField, 0x04, 3, nil, CHANNEL_CONFIGS },
  {"Channel 7", createChoiceField, 0x05, 1, nil, CHANNEL_CONFIGS },
  {"Channel 8", createChoiceField, 0x05, 2, nil, CHANNEL_CONFIGS },
  {"Channel 9", createChoiceField, 0x05, 3, nil, CHANNEL_CONFIGS },
  {"Channel 10", createChoiceField, 0x06, 1, nil, CHANNEL_CONFIGS },
  {"Channel 11", createChoiceField, 0x06, 2, nil, CHANNEL_CONFIGS },
  {"Channel 12", createChoiceField, 0x06, 3, nil, CHANNEL_CONFIGS },
  {"Channel 13", createChoiceField, 0x07, 1, nil, CHANNEL_CONFIGS },
  {"Channel 14", createChoiceField, 0x07, 2, nil, CHANNEL_CONFIGS },
  {"Channel 15", createChoiceField, 0x07, 3, nil, CHANNEL_CONFIGS },
  {"Channel 16", createChoiceField, 0x08, 1, nil, CHANNEL_CONFIGS },
  {"Channel 17", createChoiceField, 0x08, 2, nil, CHANNEL_CONFIGS },
  {"Channel 18", createChoiceField, 0x08, 3, nil, CHANNEL_CONFIGS },
  --{"Channel 19", createChoiceField, 0x09, 1, nil, CHANNEL_CONFIGS },
  --{"Channel 20", createChoiceField, 0x09, 2, nil, CHANNEL_CONFIGS },
  --{"Channel 21", createChoiceField, 0x09, 3, nil, CHANNEL_CONFIGS },
  --{"Channel 22", createChoiceField, 0x0A, 1, nil, CHANNEL_CONFIGS },
  --{"Channel 23", createChoiceField, 0x0A, 2, nil, CHANNEL_CONFIGS },
  --{"Channel 24", createChoiceField, 0x0A, 3, nil, CHANNEL_CONFIGS },
}

local failsafeParameters = {
  {"Failsafe CH1", createNumberField, 0x0B, 1, nil, 89, 211, "0us"},
  {"Failsafe CH2", createNumberField, 0x0B, 2, nil, 89, 211, "0us" },
  {"Failsafe CH3", createNumberField, 0x0B, 3, nil, 89, 211, "0us" },
  {"Failsafe CH4", createNumberField, 0x0C, 1, nil, 89, 211, "0us" },
  {"Failsafe CH5", createNumberField, 0x0C, 2, nil, 89, 211, "0us" },
  {"Failsafe CH6", createNumberField, 0x0C, 3, nil, 89, 211, "0us" },
  {"Failsafe CH7", createNumberField, 0x0D, 1, nil, 89, 211, "0us" },
  {"Failsafe CH8", createNumberField, 0x0D, 2, nil, 89, 211, "0us" },
  {"Failsafe CH9", createNumberField, 0x0D, 3, nil, 89, 211, "0us" },
  {"Failsafe CH10", createNumberField, 0x0E, 1, nil, 89, 211, "0us" },
  {"Failsafe CH11", createNumberField, 0x0E, 2, nil, 89, 211, "0us" },
  {"Failsafe CH12", createNumberField, 0x0E, 3, nil, 89, 211, "0us" },
  {"Failsafe CH13", createNumberField, 0x0F, 1, nil, 89, 211, "0us" },
  {"Failsafe CH14", createNumberField, 0x0F, 2, nil, 89, 211, "0us" },
  {"Failsafe CH15", createNumberField, 0x0F, 3, nil, 89, 211, "0us" },
  {"Failsafe CH16", createNumberField, 0x10, 1, nil, 89, 211, "0us" },
  {"Failsafe CH17", createNumberField, 0x10, 2, nil, 89, 211, "0us" },
  {"Failsafe CH18", createNumberField, 0x10, 3, nil, 89, 211, "0us" },
  --{"Failsafe CH19", createNumberField, 0x11, 1, nil, 89, 211, "0us" },
  --{"Failsafe CH20", createNumberField, 0x11, 2, nil, 89, 211, "0us" },
  --{"Failsafe CH21", createNumberField, 0x11, 3, nil, 89, 211, "0us" },
  -- {"Failsafe CH22", createNumberField, 0x12, 1, nil, 89, 211, "0us" },
  --{"Failsafe CH23", createNumberField, 0x12, 2, nil, 89, 211, "0us" },
  --{"Failsafe CH24", createNumberField, 0x12, 3, nil, 89, 211, "0us" },
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
  repeatTimes = 0
  fields = {}
  form.clear()
  parameters = parametersGroup[page]

  local line = form.addLine(pages[page])
  local field = form.addStaticText(line, nil, page.."/"..#pages)

  for index = 1, #parameters do
    local parameter = parameters[index]
    local line = form.addLine(parameter[1])
    local field = parameter[2](line, parameter)
    fields[index] = field
  end

end

local function create()
  requestInProgress = false
  refreshIndex = 0
  modifications = {}
  repeatTimes = 0
  fields = {}
  parametersGroup = {baseParameters, channelParameters, failsafeParameters}
  page = 1

  local sensor = sport.getSensor({appIdStart=0xF10, appIdEnd=0xF1F});

  print("widget.sensor:appId = ", sensor:appId())

  runPage(0)

  return {sensor=sensor}
end

local idle = false
local function wakeup(widget)
  if widget.sensor:alive() then
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
          while (parameters[refreshIndex + 1][3] == fieldId)
          do
            parameters[refreshIndex + 1][5] = value
            if value ~= nil then
              if fields[refreshIndex + 1] then
                fields[refreshIndex + 1]:enable(true)
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
            widget.sensor:appId(0xF10 + ((modifications[1][2] >> 8) & 0xFF))
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
end

local function event(widget, category, value, x, y)
  print("Event received:", category, value, x, y, KEY_EXIT_BREAK)
  if category == EVT_KEY and value == KEY_EXIT_BREAK then
    widget.sensor:idle(false)
  elseif category == EVT_KEY and value == KEY_PAGE_PREVIOUS then
    runPage(-1)
    system.killEvents(KEY_PAGE_NEXT);
  elseif category == EVT_KEY and value == KEY_PAGE_NEXT then
    runPage(1)
  end
  return false
end

local function close(widget)
  widget.sensor:idle(false)
end

local icon = lcd.loadMask("rb25.png")

local function init()
  system.registerSystemTool({name=name, icon=icon, create=create, wakeup=wakeup, event=event, close=close})
end

return {init=init}
