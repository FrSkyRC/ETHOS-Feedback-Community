-- TD/WSR Base Configure

local translations = {en="SRX Basic"}

local function name(widget)
  local locale = system.getLocale()
  return translations[locale] or translations["en"]
end

local requestInProgress = false
local refreshIndex = 0
local modifications = {}
local fields = {}
local external = 0
local open = false

local function getValue(parameter)
  if parameter[5] == nil then
    return 0
  else
    local sub = parameter[4]
    local value = ((parameter[5] >> (8 * (sub - 1))) & 0xFF)
    if parameter[2] == createNumberField and #parameter == 9 then
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

  if #parameter >= 9 then
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

local function createChoiceField(line, parameter)
  local field = form.addChoiceField(line, nil, parameter[6], function() return getValue(parameter) end, function(value) setValue(parameter, value) end)
  field:enable(false)
  return field
end

local parameters = {
  {"IMU mode",  createChoiceField, 0x14, 1, nil, {{"Off", 0x00}, {"Basic", 0x01},{"ADV",0x02}}},
  {"ADV config ", createChoiceField, 0x14, 3, nil, {{"Disable", 0}, {"Enable", 1}}},
  {"CaliHorizontal ", createChoiceField, 0x14, 2, nil, {{"Disable", 0}, {"Enable", 1}}}
}

local function create()
  requestInProgress = false
  refreshIndex = 0
  modifications = {}
  fields = {}
  open = false

  local sensor = sport.getSensor(0xC30);

  local moduleLine = form.addLine("Module")
  local field = form.addChoiceField(moduleLine, nil, {{"Internal", 0x00}, {"External", 0x01}},
    function() return external end,
    function(value)
      external = value
    end)
  moduleLine = form.addLine("")
  form.addTextButton(moduleLine, nil, "Open",
    function()
      open = true
      field:enable(false)
    end)

  for index = 1, #parameters do
    local parameter = parameters[index]
    local line = form.addLine(parameter[1])
    local field = parameter[2](line, parameter)
    fields[#fields + 1] = field
  end

  return {sensor=sensor}
end

local function wakeup(widget)
  if not open then
    return
  end
  widget.sensor:module(external)
  if requestInProgress then
    local value = widget.sensor:getParameter()
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
        refreshIndex = 0
        requestInProgress = false
        modifications[1] = nil
      end
    elseif refreshIndex <= (#parameters - 1) then
      local parameter = parameters[refreshIndex + 1]
      local fieldId = parameter[3]
      -- print("requestParameter", fieldId)
      if widget.sensor:requestParameter(fieldId) then
        requestInProgress = true
      end
    end
  end
end

local icon = lcd.loadMask("srx.png")

local function init()
  system.registerSystemTool({name=name, icon=icon, create=create, wakeup=wakeup})
end

return {init=init}