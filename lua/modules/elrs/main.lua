-- Express LRS Module

local devices = {}
local devicesRefreshTime = 0

local deviceId
local handsetId = 0xEF
local fields = {}

local fieldPopup
local fieldTime = 0
local loadQ = {}
local expectChunksRemain = -1
local fieldChunk = 0
local fieldData = {}
local currentParent
local currentExpansionPanel
local menuDepth = 0

local function create()
  devices = {}
  deviceId = nil
  fieldPopup = nil
  currentParent = nil
  currentExpansionPanel = nil
  if crsf.getSensor then
    local sensor = crsf.getSensor()
    popFrame = function() return sensor:popFrame() end
    pushFrame = function(x, y) return sensor:pushFrame(x, y) end
    return {sensor=sensor}
  else
    local sensor = {}
    sensor.popFrame = function(self) return crsf.popFrame() end
    sensor.pushFrame = function(self, x, y) return crsf.pushFrame(x, y) end
    return {sensor=sensor}
  end
end

local function createDevice(id, name, fieldsCount)
  return {id = id, name = name, fieldsCount = fieldsCount, timeout = 0}
end

local function getDevice(name)
  for i = 1, #devices do
    if devices[i].name == name then 
      return devices[i]
    end 
  end
  return nil
end

local function parseString(data, offset)
  local result = ""
  while data[offset] ~= 0 do
    result = result .. string.char(data[offset])
    offset = offset + 1
  end

  return result, offset + 1, collectgarbage("collect")
end

local function parseValue(data, offset, size)
  local result = 0
  for i = 0, size - 1 do
    result = (result << 8) + data[offset + i] 
  end
  return result, offset + size
end

local function loadAllFields()
  for i = #fields, 1, -1 do
    loadQ[#loadQ + 1] = i 
  end
end

local function reloadRelatedFields(field)
  for i = #fields, 1, -1 do
    if fields[i] ~= field and fields[i].parent == field.parent then
      if fields[i].widget ~= nil then
        fields[i].widget:enable(false)
      end
      loadQ[#loadQ + 1] = i
    end
  end
end

local function setCurrentDevice(device)
  deviceId = device.id
  fields = {}
  fieldsCount = device.fieldsCount
  for i = 1, device.fieldsCount do 
    fields[i] = {} 
  end
  loadQ = {}
  loadAllFields()
  fieldChunk = 0
  fieldData = {}
  form.clear()
end

local function parseDeviceInfoMessage(data)
  local id = data[2]
  local offset, name
  name, offset = parseString(data, 3)
  local device = getDevice(name)
  if device == nil then
    device = createDevice(id, name, data[offset + 12])
    isElrsTx = (parseValue(data, offset, 4) == 0x454C5253 and deviceId == 0xEE) or nil -- SerialNumber = 'E L R S' and ID is TX module
    devices[#devices + 1] = device
    if device.fieldsCount > 0 then
      local line = form.addLine(name, currentExpansionPanel)
      form.addTextButton(line, nil, "Setup", function()
        setCurrentDevice(device)
      end)
    end
  end
end

local function parseChoiceValues(data, offset)
  -- Split a table of byte values (string) with ; separator into a table
  local values = {}
  local opt = ''
  local b = data[offset]
  while b ~= 0 do
    if b == 59 then -- ';'
      -- print("Choice Value: " .. opt)
      values[#values + 1] = {opt, #values}
      opt = ''
    else
      opt = opt .. string.char(b)
    end
    offset = offset + 1
    b = data[offset]
  end

  values[#values + 1] = {opt, #values}
  return values, offset + 1, collectgarbage("collect")
end

-- UINT8 (0) / UINT16 (2)
local function addUnsignedLine(widget, field, name, fieldData, offset, size)
  local min, max, default, unit
  field.value, offset = parseValue(fieldData, offset, size)
  min, offset = parseValue(fieldData, offset, size)
  max, offset = parseValue(fieldData, offset, size)
  default, offset = parseValue(fieldData, offset, size)
  unit = parseString(fieldData, offset)
  if field.widget == nil then
    local line = form.addLine(name, currentExpansionPanel)
    field.widget = form.addNumberField(line, nil, min, max, 
      function()
        return field.value
      end, 
      function(value)
        field.value = value
        local frame = {deviceId, handsetId, field.id}
        for i = 1, size do
          table.insert(frame, 4, value & 0xFF)
          value = value >> 8
        end
        widget.sensor:pushFrame(0x2D, frame)
        reloadRelatedFields(field)
      end)
    field.widget:enableInstantChange(true)
  else
    field.widget:enable(true)
  end
end

-- Select (9)
local function addChoiceLine(widget, field, name, fieldData, offset)
  local values
  values, offset = parseChoiceValues(fieldData, offset)
  field.value = fieldData[offset]
  -- local unit = parseString(fieldData, offset + 4)
  if field.widget == nil then
    local line = form.addLine(name, currentExpansionPanel)
    field.widget = form.addChoiceField(line, nil, values, 
      function()
        return field.value
      end, 
      function(value)
        field.value = value
        widget.sensor:pushFrame(0x2D, {deviceId, handsetId, field.id, value})
      end)
    if field.widget.title ~= nil then
      field.widget:title(name)
    end
  else
    field.widget:enable(true)
  end
end

-- Folder (11)
local function addFolderLine(field, name, fieldData, offset)
  currentExpansionPanel = form.addExpansionPanel(name)
  currentParent = field
end

-- Info (12)
local function addInfoLine(field, name, fieldData, offset)
  field.value, offset = parseString(fieldData, offset)
  if field.widget == nil then
    local line = form.addLine(name, currentExpansionPanel)
    field.widget = form.addStaticText(line, nil, field.value)
  end
end

-- Command (13)
local function addCommandLine(widget, field, name, fieldData, offset)
  field.status = fieldData[offset]
  field.timeout = fieldData[offset + 1]
  field.info = parseString(fieldData, offset + 2)
  -- print("Status: " .. field.status .. ", Info: " .. field.info)
  if field.dialog then
    if field.status == 0 then
      field.dialog:close()
      -- field.dialog = nil
    else
      if field.status == 3 then
        field.dialog:buttons({
          {
            label = "OK",
            action = function()
              widget.sensor:pushFrame(0x2D, {deviceId, handsetId, field.id, 4}) -- lcsConfirmed
              fieldTimeout = os.time() + field.timeout / 100 -- we are expecting an immediate response
              field.status = 4
            end
          }, 
          {label = "Cancel"}
        })
      else
        field.dialog:buttons({
          {
            label = "Cancel",
            action = function()
              widget.sensor:pushFrame(0x2D, {deviceId, handsetId, field.id, 5}) -- lcsCancelled
              fieldPopup = nil
              return true
            end
          }
        })
      end
      field.dialog:message(field.info)
    end
  elseif field.widget == nil then
    local line = form.addLine("", currentExpansionPanel)
    field.widget = form.addTextButton(line, nil, name, function()
      if field.status < 4 then
        field.status = 1
        widget.sensor:pushFrame(0x2D, {deviceId, handsetId, field.id, field.status})
        fieldPopup = field
        field.dialog = form.openDialog(name, field.info, {
          {
            label = "Cancel",
            action = function()
              widget.sensor:pushFrame(0x2D, {deviceId, handsetId, field.id, 5}) -- lcsCancelled
              fieldPopup = nil
              return true
            end
          }
        })
      end
    end)
  end
end

local function parseParameterInfoMessage(widget, data)
  local fieldId = (fieldPopup and fieldPopup.id) or loadQ[#loadQ]
  if data[2] ~= deviceId or data[3] ~= fieldId then
    fieldData = {}
    fieldChunk = 0
    return
  end
  local field = fields[fieldId]
  local chunksRemain = data[4]
  -- If no field or the chunksremain changed when we have data, don't continue
  if not field or (chunksRemain ~= expectChunksRemain and #fieldData ~= 0) then return end
  expectChunksRemain = chunksRemain - 1
  for i = 5, #data do fieldData[#fieldData + 1] = data[i] end
  if chunksRemain > 0 then
    fieldChunk = fieldChunk + 1
  else
    loadQ[#loadQ] = nil
    if #fieldData > 3 then
      local offset, type, name, hidden
      field.id = fieldId
      field.parent = fieldData[1]
      type = fieldData[2] & 0x7F
      hidden = fieldData[2] & 0x80

      if hidden == 0 then
        name, offset = parseString(fieldData, 3)
        -- print("Field: " .. name .. ", Type: " .. type)

        if currentParent ~= nil and field.parent ~= currentParent.id then
          currentExpansionPanel = nil
          currentParent = nil
        end

        if type == 0 then
          addUnsignedLine(widget, field, name, fieldData, offset, 1)
        elseif type == 2 then
          addUnsignedLine(widget, field, name, fieldData, offset, 2)
        elseif type == 9 then
          addChoiceLine(widget, field, name, fieldData, offset)
        elseif type == 11 then
          addFolderLine(field, name, fieldData, offset)
        elseif type == 12 then
          addInfoLine(field, name, fieldData, offset)
        elseif type == 13 then
          addCommandLine(widget, field, name, fieldData, offset)
        else
          print("Field '" .. name .. "' type=" .. type .. " not supported")
        end
      end
    end

    fieldChunk = 0
    fieldData = {}
  end
end

local function wakeup(widget)
  local time = os.clock()
  while true do
    command, data = widget.sensor:popFrame()
    if command == nil then
      break
    elseif command == 0x29 then
      parseDeviceInfoMessage(data)
      menuDepth = 0
    elseif command == 0x2B then
      menuDepth = 1
      parseParameterInfoMessage(widget, data)
      if #loadQ > 0 or expectChunksRemain >= 0 then
        fieldTime = 0 -- request next chunk immediately
      elseif fieldPopup then
        fieldTime = time + fieldPopup.timeout / 100
      end
    end
  end

  if fieldPopup then        
    if time > fieldTime and fieldPopup.status ~= 3 then
      widget.sensor:pushFrame(0x2D, {deviceId, handsetId, fieldPopup.id, 6}) -- lcsQuery
      fieldTime = time + fieldPopup.timeout / 100
    end
  elseif time > devicesRefreshTime and deviceId == nil then
    devicesRefreshTime = time + 1 -- 1s
    widget.sensor:pushFrame(0x28, {0x00, 0xEA})
  elseif time > fieldTime and deviceId ~= nil then
    if #loadQ > 0 then
      widget.sensor:pushFrame(0x2C, {deviceId, handsetId, loadQ[#loadQ], fieldChunk})
      fieldTime = time + 0.5
    end
  end
end

local function event(widget, category, value, x, y)
  if menuDepth > 0 then
    if category == EVT_CLOSE or (category == EVT_KEY and value == KEY_RTN_BREAK) then
      form.clear()
      devices = {}
      deviceId = nil
      fieldPopup = nil
      currentParent = nil
      currentExpansionPanel = nil
      return true
    end
  end
  return false
end

local function init()
  system.registerElrsModule({configure = {name = "ELRS Configuration", create = create, wakeup = wakeup, event = event, close = close}})
end

return {init = init}
