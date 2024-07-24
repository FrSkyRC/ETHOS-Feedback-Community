-- SRX Configure
local translations = {en="SRX Stable"}

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
local pages = {"Stable System 1", "Stable System 2"}
local parameters = {}
local external = 0
local open = false

local function getValue(parameter)
  if parameter[5] == nil then
    return 0
  else
    local sub = parameter[4]
    local value = ((parameter[5] >> (8 * (sub - 1))) & 0xFF)
    if #parameter == 9 then
      value = value - parameter[9]
    end
    return value
  end
end

local function setValue(parameter, value)
  local sub = parameter[4]
  local D1 = parameter[5] & 0xFF
  local D2 = (parameter[5] >> 8) & 0xFF
  local D3 = (parameter[5] >> 16) & 0xFF

  if #parameter == 9 then
    value = value + parameter[9]
  end

  if sub == 1 then
    D1 = value
  elseif sub == 2 then
    D2 = value
  elseif sub == 3 then
    D3 = value
  end
  value = D1 + D2 * 256 + D3 * 256 * 256
  local fieldId = parameter[3]
  modifications[#modifications+1] = {fieldId, value}
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

local parameters1 = {
  -- { name, type, page, sub, value, min, max, unit, offset }
  {"Stabilizing", createChoiceField, 0x40, 1, nil, {{"ON", 1}, {"OFF", 0}} },
  {"Self Check", createChoiceField, 0x4C, 1, nil, {{"Disable", 0}, {"Enable", 1}} },
  {"Quick Mode",    createChoiceField, 0x41, 1, nil, {{"Disable", 0}, {"Enable", 1}} },
  {"WingType",      createChoiceField, 0x41, 2, nil, {{"Normal", 0}, {"Delta", 1}, {"VTail", 2}} },
  {"Mounting Type", createChoiceField, 0x41, 3, nil, {{"Horizontal", 0}, {"Horizontal Reverse", 1}, {"Vertical", 2}, {"Vertical Reverse", 3}} },
  {"CH5 Mode",      createChoiceField, 0x42, 1, nil, {{"AIL2", 0}, {"AUX1", 1}} },
  {"CH6 Mode",      createChoiceField, 0x42, 2, nil, {{"ELE2", 0}, {"AUX2", 1}} },
  {"AIL Direction", createChoiceField, 0x42, 3, nil, {{"Normal", 0}, {"Invers", 0xFF}} },
  {"ELE Direction", createChoiceField, 0x43, 1, nil, {{"Normal", 0}, {"Invers", 0xFF}} },
  {"RUD Direction", createChoiceField, 0x43, 2, nil, {{"Normal", 0}, {"Invers", 0xFF}} },
  {"AIL2 Direction", createChoiceField, 0x43, 3, nil, {{"Normal", 0}, {"Invers", 0xFF}} },
  {"ELE2 Direction", createChoiceField, 0x44, 1, nil, {{"Normal", 0}, {"Invers", 0xFF}} },
  {"AIL Stab Gain", createNumberField, 0x44, 2, nil, 0, 200, "%"},
  {"ELE Stab Gain", createNumberField, 0x44, 3, nil, 0, 200, "%"},
  {"RUD Stab Gain", createNumberField, 0x45, 1, nil, 0, 200, "%"},
  {"AIL Auto 1v1 Gain", createNumberField, 0x46, 1, nil, 0, 200, "%"},
  {"ELE Auto 1v1 Gain", createNumberField, 0x46, 2, nil, 0, 200, "%"},
  {"ELE Hover Gain", createNumberField, 0x47, 2, nil, 0, 200, "%"},
  {"RUD Hover Gain", createNumberField, 0x47, 3, nil, 0, 200, "%"},
  {"AIL Knife Gain", createNumberField, 0x48, 1, nil, 0, 200, "%"},
  {"RUD Knife Gain", createNumberField, 0x48, 3, nil, 0, 200, "%"},
  {"AIL Auto 1v1 Offset", createNumberField, 0x49, 1, nil, -20, 20, "%", 0x80},
  {"ELE Auto 1v1 offset", createNumberField, 0x49, 2, nil, -20, 20, "%", 0x80},
  {"ELE Hover Offset", createNumberField, 0x4A, 2, nil, -20, 20, "%", 0x80},
  {"RUD Hover Offset", createNumberField, 0x4A, 3, nil, -20, 20, "%", 0x80},
  {"AIL Knife Offset", createNumberField, 0x4B, 1, nil, -20, 20, "%", 0x80},
  {"RUD Knife Offset", createNumberField, 0x4B, 3, nil, -20, 20, "%", 0x80},
  {"Roll Degree ", createNumberField, 0x4D, 1, nil, 0, 80, " degree"},
  {"Pitch Degree", createNumberField, 0x4D, 2, nil, 0, 80, " degree"},
}

local parameters2 = {
  -- { name, type, page, sub, value, min, max, unit, offset }
  {"Stabilizing", createChoiceField, 0x70, 1, nil, {{"ON", 1}, {"OFF", 0}} },
  {"Self Check", createChoiceField, 0x7C, 1, nil, {{"Disable", 0}, {"Enable", 1}} },
  {"Quick Mode",    createChoiceField, 0x71, 1, nil, {{"Disable", 0}, {"Enable", 1}} },
  {"WingType",      createChoiceField, 0x71, 2, nil, {{"Normal", 0}, {"Delta", 1}, {"VTail", 2}} },
  -- {"Mounting Type", createChoiceField, 0x71, 3, nil, {{"Horizontal", 0}, {"Horizontal Reverse", 1}, {"Vertical", 2}, {"Vertical Reverse", 3}} },
  {"CH10 Mode",      createChoiceField, 0x72, 1, nil, {{"AIL4", 0}, {"AUX3", 1}} },
  {"CH11 Mode",      createChoiceField, 0x72, 2, nil, {{"ELE4", 0}, {"AUX4", 1}} },
  {"AIL3 Direction", createChoiceField, 0x72, 3, nil, {{"Normal", 0}, {"Invers", 0xFF}} },
  {"ELE3 Direction", createChoiceField, 0x73, 1, nil, {{"Normal", 0}, {"Invers", 0xFF}} },
  {"RUD2 Direction", createChoiceField, 0x73, 2, nil, {{"Normal", 0}, {"Invers", 0xFF}} },
  {"AIL4 Direction", createChoiceField, 0x73, 3, nil, {{"Normal", 0}, {"Invers", 0xFF}} },
  {"ELE4 Direction", createChoiceField, 0x74, 1, nil, {{"Normal", 0}, {"Invers", 0xFF}} },
  {"AIL3-4 Stab Gain", createNumberField, 0x74, 2, nil, 0, 200, "%"},
  {"ELE3-4 Stab Gain", createNumberField, 0x74, 3, nil, 0, 200, "%"},
  {"RUD2 Stab Gain", createNumberField, 0x75, 1, nil, 0, 200, "%"},
  {"AIL3-4 Auto 1v1 Gain", createNumberField, 0x76, 1, nil, 0, 200, "%"},
  {"ELE3-4 Auto 1v1 Gain", createNumberField, 0x76, 2, nil, 0, 200, "%"},
  {"ELE3-4 Hover Gain", createNumberField, 0x77, 2, nil, 0, 200, "%"},
  {"RUD2 Hover Gain", createNumberField, 0x77, 3, nil, 0, 200, "%"},
  {"AIL3-4 Knife Gain", createNumberField, 0x78, 1, nil, 0, 200, "%"},
  {"RUD2 Knife Gain", createNumberField, 0x78, 3, nil, 0, 200, "%"},
  {"AIL3-4 Auto 1v1 Offset", createNumberField, 0x79, 1, nil, -20, 20, "%", 0x80},
  {"ELE3-4 Auto 1v1 offset", createNumberField, 0x79, 2, nil, -20, 20, "%", 0x80},
  {"ELE3-4 Hover Offset", createNumberField, 0x7A, 2, nil, -20, 20, "%", 0x80},
  {"RUD2 Hover Offset", createNumberField, 0x7A, 3, nil, -20, 20, "%", 0x80},
  {"AIL3-4 Knife Offset", createNumberField, 0x7B, 1, nil, -20, 20, "%", 0x80},
  {"RUD2 Knife Offset", createNumberField, 0x7B, 3, nil, -20, 20, "%", 0x80},
  {"Roll Degree ", createNumberField, 0x7D, 1, nil, 0, 80, " degree"},
  {"Pitch Degree", createNumberField, 0x7D, 2, nil, 0, 80, " degree"},
}


local function runPage(step)
  page = page + step
  if page > 2 then
    page = 2
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

  local moduleLine = form.addLine("Module")
  local field = form.addChoiceField(moduleLine, nil, {{"Internal", 0x00}, {"External", 0x01}},
    function() return external end,
    function(value)
      external = value
    end)
  field:enable(not open)
  moduleLine = form.addLine("")
  form.addTextButton(moduleLine, nil, "Open",
    function()
      open = true
      field:enable(false)
    end)

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
  parametersGroup = {parameters1, parameters2}
  page = 1
  open = false

  local sensor = sport.getSensor(0x0c30);

  print("widget.sensor:appId = ", sensor:appId())

  runPage(0)

  return {sensor=sensor}
end


local idle = false
local function wakeup(widget)
 -- if widget.sensor:alive() then
 --   if idle == false then
 --     widget.sensor:idle()
 --     idle = true
 --   end
    if not open then
      return
    end
    widget.sensor:module(external)
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
            widget.sensor:appId(0xF00 + ((modifications[1][2] >> 8) & 0xFF))
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
 -- end
end

local function event(widget, category, value, x, y)
  print("Event received:", category, value, x, y, KEY_EXIT_BREAK)
  if  category == EVT_KEY and value == KEY_PAGE_PREVIOUS then
    runPage(-1)
    system.killEvents(KEY_PAGE_NEXT);
  elseif category == EVT_KEY and value == KEY_PAGE_NEXT then
    runPage(1)
  end
  return false
end

local icon = lcd.loadMask("srx.png")

local function init()
  system.registerSystemTool({name=name, icon=icon, create=create, wakeup=wakeup, event=event})
end

return {init=init}
