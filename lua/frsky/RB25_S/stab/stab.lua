-- RB25S Stab Configure

local translations = {en="RB25S stab"}

local function name(widget)
  local locale = system.getLocale()
  return translations[locale] or translations["en"]
end

local requestInProgress = false
local refreshIndex = 0
local modifications = {}
local fields = {}
local page = 0
local pages = {"Stable system 1", "Stable system 2"}
local parameters = {}
local parametersGroup = {}
local idle = false

local function getValue(parameter)
  if parameter[5] == nil then
    return 0
  else
    local sub = parameter[4]
    local value = ((parameter[5] >> (8 * (sub - 1))) & 0xFF)
    if #parameter >= 9 then
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

local function createNumberField(line, parameter)
  local field = form.addNumberField(line, nil, parameter[6], parameter[7], function() return getValue(parameter) end, function(value) setValue(parameter, value) end)
  field:enableInstantChange(false)
  if #parameter >= 8 then
    field:suffix(parameter[8])
  end
  if #parameter >= 10 then
    field:prefix(parameter[10])
  end
  field:enable(false)
  return field
end

local function createChoiceField(line, parameter)
  local field = form.addChoiceField(line, nil, parameter[6], function() return getValue(parameter) end, function(value) setValue(parameter, value) end)
  field:enable(false)
  return field
end

local function createTextButton(line, parameter)
  local field = form.addTextButton(line, nil, parameter[6], function() return setValue(parameter, parameter[7]) end)
  field:enable(false)
  return field
end

local function createTextButton(line, parameter)
  local field = form.addTextButton(line, nil, parameter[6], function() setValue(parameter, parameter[7]) end)
  field:enable(false)
  return field
end

local function createResetButton(line, parameter)
  local field = form.addTextButton(line, nil, parameter[6], function()
    local buttons = {
      {label="Cancel", action=function () return true end},
      {label="Reset", action=function() setValue(parameter, parameter[7]) end},
    }
    local dialog = form.openDialog({
      title="Confirm reset",
      message="Settings are about to be reset.\nPlease confirm to continue.",
      width=system.getVersion().lcdWidth * 2 / 3,
      buttons=buttons
    })
  end)
  field:enable(false)
  return field
end

local parameters1 = {
  -- { name, type, page, sub, value, min, max, unit, offset }
  {"Reset", createResetButton, 0xA5, 3, nil, "Start", 0x81},
  {"Stabilizing", createChoiceField, 0xA5, 1, nil, {{"Off", 0}, {"On", 1}} },
  {"Self check", createTextButton, 0xA5, 2, nil, "Start", 1},
  {"Quick mode", createChoiceField, 0xA6, 1, nil, {{"Disable", 0}, {"Enable", 1}} },

  {"Wing type", createChoiceField, 0xA6, 2, nil, {{"Normal", 0}, {"Delta", 1}, {"VTail", 2}} },
  {"Mounting type", createChoiceField, 0xA6, 3, nil, {{"Horizontal", 0}, {"Horizontal reverse", 1}, {"Vertical", 2}, {"Vertical reverse", 3}} },

  {"CH1 mode", createChoiceField, 0xA7, 1, nil, {{"AIL1", 0}, {"AUX", 1}} },
  {"CH2 mode", createChoiceField, 0xA7, 2, nil, {{"ELE1", 0}, {"AUX", 1}} },
  {"CH4 mode", createChoiceField, 0xA7, 3, nil, {{"RUD", 0}, {"AUX", 1}} },
  {"CH5 mode", createChoiceField, 0xA8, 1, nil, {{"AIL2", 0}, {"AUX", 1}} },
  {"CH6 mode", createChoiceField, 0xA8, 2, nil, {{"ELE2", 0}, {"AUX", 1}} },

  {"AIL inverted", createChoiceField, 0xA9, 1, nil, {{"Off", 0}, {"On", 0xFF}} },
  {"ELE inverted", createChoiceField, 0xA9, 2, nil, {{"Off", 0}, {"On", 0xFF}} },
  {"RUD inverted", createChoiceField, 0xA9, 3, nil, {{"Off", 0}, {"On", 0xFF}} },
  {"AIL2 inverted", createChoiceField, 0xAA, 1, nil, {{"Off", 0}, {"On", 0xFF}} },
  {"ELE2 inverted", createChoiceField, 0xAA, 2, nil, {{"Off", 0}, {"On", 0xFF}} },

  {"AIL stab gain", createNumberField, 0xAB, 1, nil, 0, 200, "%"},
  {"ELE stab gain", createNumberField, 0xAB, 2, nil, 0, 200, "%"},
  {"RUD stab gain", createNumberField, 0xAB, 3, nil, 0, 200, "%"},
  {"AIL auto 1v1 gain", createNumberField, 0xAC, 1, nil, 0, 200, "%"},
  {"ELE auto 1v1 gain", createNumberField, 0xAC, 2, nil, 0, 200, "%"},
  {"ELE hover gain", createNumberField, 0xAD, 2, nil, 0, 200, "%"},
  {"RUD hover gain", createNumberField, 0xAD, 3, nil, 0, 200, "%"},
  {"AIL knife gain", createNumberField, 0xAE, 1, nil, 0, 200, "%"},
  {"RUD knife gain", createNumberField, 0xAE, 3, nil, 0, 200, "%"},

  {"AIL auto 1v1 offset", createNumberField, 0xAF, 1, nil, -20, 20, "%", 0x80},
  {"ELE auto 1v1 offset", createNumberField, 0xAF, 2, nil, -20, 20, "%", 0x80},
  {"ELE hover offset", createNumberField, 0xB0, 2, nil, -20, 20, "%", 0x80},
  {"RUD hover offset", createNumberField, 0xB0, 3, nil, -20, 20, "%", 0x80},
  {"AIL knife offset", createNumberField, 0xB1, 1, nil, -20, 20, "%", 0x80},
  {"RUD knife offset", createNumberField, 0xB1, 3, nil, -20, 20, "%", 0x80},

  {"Roll degree", createNumberField, 0xB3, 1, nil, 0, 80, "°"},
  {"Pitch degree", createNumberField, 0xB3, 2, nil, 0, 80, "°"},

  {"AIL1 stick priority", createNumberField, 0xB4, 1, nil, 0, 100, "%"},
  {"AIL1 rev. stick priority", createNumberField, 0xB4, 2, nil, 0, 100, "%", 0, "-"},
  {"ELE1 stick priority", createNumberField, 0xB5, 1, nil, 0, 100, "%"},
  {"ELE1 rev. stick priority", createNumberField, 0xB5, 2, nil, 0, 100, "%", 0, "-"},
  {"RUD stick priority", createNumberField, 0xB6, 1, nil, 0, 100, "%"},
  {"RUD rev. stick priority", createNumberField, 0xB6, 2, nil, 0, 100, "%", 0, "-"},
  {"AIL2 stick priority", createNumberField, 0xB7, 1, nil, 0, 100, "%"},
  {"AIL2 rev. stick priority", createNumberField, 0xB7, 2, nil, 0, 100, "%", 0, "-"},
  {"ELE2 stick priority", createNumberField, 0xB8, 1, nil, 0, 100, "%"},
  {"ELE2 rev. stick priority", createNumberField, 0xB8, 2, nil, 0, 100, "%", 0, "-"},
}

local parameters2 = {
  -- { name, type, page, sub, value, min, max, unit, offset }
  {"Reset", createResetButton, 0xC0, 3, nil, "Start", 0x81},
  {"Stabilizing", createChoiceField, 0xC0, 1, nil, {{"Off", 0}, {"On", 1}} },
  {"Self check", createTextButton, 0xC0, 2, nil, "Start", 1},
  {"Quick mode", createChoiceField, 0xC1, 1, nil, {{"Disable", 0}, {"Enable", 1}} },

  {"Wing type", createChoiceField, 0xC1, 2, nil, {{"Normal", 0}, {"Delta", 1}, {"VTail", 2}} },
  {"Mounting type", createChoiceField, 0xC1, 3, nil, {{"Horizontal", 0}, {"Horizontal reverse", 1}, {"Vertical", 2}, {"Vertical reverse", 3}} },

  {"CH7 mode", createChoiceField, 0xC2, 1, nil, {{"AIL3", 0}, {"AUX", 1}} },
  {"CH8 mode", createChoiceField, 0xC2, 2, nil, {{"ELE3", 0}, {"AUX", 1}} },
  {"CH9 mode", createChoiceField, 0xC2, 3, nil, {{"RUD2", 0}, {"AUX", 1}} },
  {"CH10 mode", createChoiceField, 0xC3, 1, nil, {{"AIL4", 0}, {"AUX", 1}} },
  {"CH11 mode", createChoiceField, 0xC3, 2, nil, {{"ELE4", 0}, {"AUX", 1}} },

  {"AIL3 inverted", createChoiceField, 0xC4, 1, nil, {{"Off", 0}, {"On", 0xFF}} },
  {"ELE3 inverted", createChoiceField, 0xC4, 2, nil, {{"Off", 0}, {"On", 0xFF}} },
  {"RUD2 inverted", createChoiceField, 0xC4, 3, nil, {{"Off", 0}, {"On", 0xFF}} },
  {"AIL4 inverted", createChoiceField, 0xC5, 1, nil, {{"Off", 0}, {"On", 0xFF}} },
  {"ELE4 inverted", createChoiceField, 0xC5, 2, nil, {{"Off", 0}, {"On", 0xFF}} },

  {"AIL3-4 stab gain", createNumberField, 0xC6, 1, nil, 0, 200, "%"},
  {"ELE3-4 stab gain", createNumberField, 0xC6, 2, nil, 0, 200, "%"},
  {"RUD2 stab gain", createNumberField, 0xC6, 3, nil, 0, 200, "%"},
  {"AIL3-4 auto 1v1 gain", createNumberField, 0xC7, 1, nil, 0, 200, "%"},
  {"ELE3-4 auto 1v1 gain", createNumberField, 0xC7, 2, nil, 0, 200, "%"},
  {"ELE3-4 hover gain", createNumberField, 0xC8, 2, nil, 0, 200, "%"},
  {"RUD2 hover gain", createNumberField, 0xC8, 3, nil, 0, 200, "%"},
  {"AIL3-4 knife gain", createNumberField, 0xC9, 1, nil, 0, 200, "%"},
  {"RUD2 knife gain", createNumberField, 0xC9, 3, nil, 0, 200, "%"},

  {"AIL3-4 auto 1v1 offset", createNumberField, 0xCA, 1, nil, -20, 20, "%", 0x80},
  {"ELE3-4 auto 1v1 offset", createNumberField, 0xCA, 2, nil, -20, 20, "%", 0x80},
  {"ELE3-4 hover offset", createNumberField, 0xCB, 2, nil, -20, 20, "%", 0x80},
  {"RUD2 hover offset", createNumberField, 0xCB, 3, nil, -20, 20, "%", 0x80},
  {"AIL3-4 knife offset", createNumberField, 0xCC, 1, nil, -20, 20, "%", 0x80},
  {"RUD2 knife offset", createNumberField, 0xCC, 3, nil, -20, 20, "%", 0x80},

  {"Roll degree", createNumberField, 0xCD, 1, nil, 0, 80, "°"},
  {"Pitch degree", createNumberField, 0xCD, 2, nil, 0, 80, "°"},

  {"AIL3 stick priority", createNumberField, 0xCE, 1, nil, 0, 100, "%"},
  {"AIL3 rev. stick priority", createNumberField, 0xCE, 2, nil, 0, 100, "%", 0, "-"},
  {"ELE3 stick priority", createNumberField, 0xCF, 1, nil, 0, 100, "%"},
  {"ELE3 rev. stick priority", createNumberField, 0xCF, 2, nil, 0, 100, "%", 0, "-"},
  {"RUD2 stick priority", createNumberField, 0xD0, 1, nil, 0, 100, "%"},
  {"RUD2 rev. stick priority", createNumberField, 0xD0, 2, nil, 0, 100, "%", 0, "-"},
  {"AIL4 stick priority", createNumberField, 0xD1, 1, nil, 0, 100, "%"},
  {"AIL4 rev. stick priority", createNumberField, 0xD1, 2, nil, 0, 100, "%", 0, "-"},
  {"ELE4 stick priority", createNumberField, 0xD2, 1, nil, 0, 100, "%"},
  {"ELE4 rev. stick priority", createNumberField, 0xD2, 2, nil, 0, 100, "%", 0, "-"},
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
  requestInProgress = false
  refreshIndex = 0
  modifications = {}
  fields = {}
  parametersGroup = {parameters1, parameters2}
  page = 1

  local sensor = sport.getSensor({appIdStart=0x0F10, appIdEnd=0x0F1F});

  print("widget.sensor:appId = ", sensor:appId())

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
          widget.sensor:appId(0x0F10 + ((modifications[1][2] >> 8) & 0xFF))
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
