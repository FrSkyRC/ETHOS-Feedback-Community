local requestInProgress = false
local refreshIndex = 0
local modifications = {}
local fields = {}

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

-- local function createTextButton(line, parameter)
--   local field = form.addTextButton(line, nil, parameter[6], function() setValue(parameter, parameter[7]) end)
--   field:enable(false)
--   return field
-- end

local parameters = {
  {STR("GyroMode"),  createChoiceField, 0xA4, 1, nil, {{STR("Off"), 0x00}, {STR("Basic"), 0x01},{STR("ADV"),0x02}}},
  {STR("ADVConfig"), createChoiceField, 0xA4, 3, nil, {{STR("Disable"), 0}, {STR("Enable"), 1}}},
  -- {"Calibrate horizontal", createTextButton, 0xA4, 2, nil, "Start", 1}
}

local restoreFileName = ""
local addressIndex = 3
local valueIndex = 5
local function buildBackupForm(ePanel, focusRefresh)
  ePanel:clear()

  local ePanelLine = ePanel:addLine("")
  local slots = form.getFieldSlots(ePanelLine, {270, "- "..STR("Load").." -","- "..STR("Save").." -"})

  form.addFileField(ePanelLine, slots[1], "", "csv+ext", function ()
    return restoreFileName
  end, function (newFile)
    restoreFileName = newFile
  end)

  form.addTextButton(ePanelLine, slots[2], STR("Load"), function()
    if refreshIndex == 0 then
      Dialog.openDialog({title = STR("LoadFailed"), message = STR("ReadSettingsFirstly"), buttons = {{label = STR("OK"), action = function () Dialog.closeDialog() end}},})
      return
    end

    if not restoreFileName or restoreFileName == "" then
      Dialog.openDialog({title = STR("NoFileSelected"), message = STR("SelectFileFirstly"), buttons = {{label = STR("OK"), action = function () Dialog.closeDialog() end}},})
      return
    end

    local file = io.open(restoreFileName, "r+")
    if file == nil then
      Dialog.openDialog({title = STR("LoadFailed"), message = STR("FileReadError"), buttons = {{label = STR("OK"), action = function () Dialog.closeDialog() end}},})
      return
    end

    local line = file:read("l")
    while line do
      local lineData = {}
      for value in line:gmatch("([^,]+)") do
        lineData[#lineData + 1] = tonumber(value)
        if #lineData >= 2 then
          break
        end
      end
      if lineData[1] ~= nil and lineData[2] ~= nil then
        modifications[#modifications + 1] = {lineData[1], lineData[2]}
      end
      line = file:read("l")
    end
    file:close()
    for index = 1, #fields do
      if fields[index] then
        fields[index]:enable(false)
      end
    end
    Dialog.openDialog({title = STR("ConfigurationLoaded"), message = STR("ConfigFileLoaded", {name = '\n' .. restoreFileName}), buttons = {{label = STR("OK"), action = function () Dialog.closeDialog() end}},})
  end)

  local button = form.addTextButton(ePanelLine, slots[3], STR("Save"), function()
    if refreshIndex == 0 then
      Dialog.openDialog({title = STR("SaveFailed"), message = STR("ReadSettingsFirstly"), buttons = {{label = STR("OK"), action = function () Dialog.closeDialog() end}},})
      return
    end

    local output = ""
    local addresses = {}
    local fullTable = parameters

    for pi = 1, #fullTable do
      local find = false
      local param = fullTable[pi]
      for ai = 1, #addresses do
        if addresses[ai] == param[addressIndex] then
          find = true
          break
        end
      end
      if not find and param[valueIndex] ~= nil then
        output = output .. param[addressIndex] .. "," .. param[valueIndex] .. ",\n"
        addresses[#addresses + 1] = param[addressIndex]
      end
    end

    local file
    local configPrefix = model.name():gsub("%s", "_")
    local configSuffix = ".csv"
    local fileName = configPrefix .. configSuffix
    file = io.open(fileName, "r")
    if file ~= nil then
      for i = 2, 99 do
        fileName = configPrefix .. string.format("%02d", i) .. configSuffix
        file = io.open(fileName, "r")
        if file == nil then
          break
        end
        file:close()
        if i == 99 then
          Dialog.openDialog({title = STR("SaveFailed"), message = STR("CannotSaveToFile"), buttons = {{label = STR("OK"), action = function () Dialog.closeDialog() end}},})
          return
        end
      end
    end

    file = io.open(fileName, "w+")
    if file ~= nil then
      file:write(output)
      file:close()
      Dialog.openDialog({title = STR("configurationSaved"), message = STR("ConfigSaveToFile", {fileName = "\n"..fileName}), buttons = {{label = STR("OK"), action = function ()
        Dialog.closeDialog()
        buildBackupForm(ePanel, true)
      end}},})
    else
      Dialog.openDialog({title = STR("SaveFailed"), message = STR("FSError"), buttons = {{label = STR("OK"), action = function () Dialog.closeDialog() end}},})
    end
  end)
  if focusRefresh then
    button:focus()
  else
    ePanel:open(false)
  end
end

local function pageInit()
  requestInProgress = false
  refreshIndex = 0
  modifications = {}
  fields = {}

  for index = 1, #parameters do
    local parameter = parameters[index]
    local line = form.addLine(parameter[1])
    local field = parameter[2](line, parameter)
    fields[index] = field
  end
end

local function wakeup(widget)
  if requestInProgress then
    local value = Sensor.getParameter()
    -- print("Sensor.getParameter = ", value)
    if value then
      local fieldId = value % 256
      local parameter = parameters[refreshIndex + 1]
      if fieldId == parameter[3] then
        value = math.floor(value / 256)
        while parameters[refreshIndex + 1][3] == fieldId do
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
      if Sensor.writeParameter(modifications[1][1], modifications[1][2]) == true then
        if modifications[1][1] == 0x13 then -- appId changed
          Sensor.appId(Sensor.APPID + ((modifications[1][2] >> 8) & 0xFF))
        end
        refreshIndex = 0
        requestInProgress = false
        table.remove(modifications, 1)
      end
    elseif refreshIndex <= (#parameters - 1) then
      local parameter = parameters[refreshIndex + 1]
      -- print("requestParameter", parameter[3])
      if Sensor.requestParameter(parameter[3]) then
        requestInProgress = true
      end
    end
  end
end

return {pageInit = pageInit, wakeup = wakeup}
