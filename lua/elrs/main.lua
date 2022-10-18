-- ELRS Configuration

local translations = {en="ELRS Configuration"}

local function name(widget)
  local locale = system.getLocale()
  return translations[locale] or translations["en"]
end

local devices = { }
local devicesRefreshTime = 0

local deviceId
local handsetId = 0xEF
local fields = {}

local fieldPopup
local fieldTime = 0
local loadQ = {}
local fieldChunk = 0
local fieldData = {}
local currentParent

local function create()
  devices = {}
  deviceId = nil
  return {}
end

local function createDevice(id, name, fieldsCount)
  local device = {
    id = id,
    name = name,
    fieldsCount = fieldsCount,
    timeout = 0
  }
  return device
end

local function getDevice(name)
  for i=1, #devices do
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
  return result
end

local function setCurrentDevice(device)
  deviceId = device.id
  fields = {}
  fieldsCount = device.fieldsCount
  for i = 1, device.fieldsCount do
    fields[i] = { }
  end
  loadQ = {}
  for fieldId = fieldsCount, 1, -1 do
    loadQ[#loadQ + 1] = fieldId
  end
  fieldChunk = 0
  fieldData = {}
  form.clear()
end

local function parseDeviceInfoMessage(data)
  local id = data[2]
  local offset, name
  name, offset = parseString(data, 3)
  print("Device: " .. name)
  local device = getDevice(name)
  if device == nil then
    device = createDevice(id, name, data[offset + 12])
    isElrsTx = (parseValue(data, offset, 4) == 0x454C5253 and deviceId == 0xEE) or nil -- SerialNumber = 'E L R S' and ID is TX module
    devices[#devices + 1] = device
    local line = form.addLine(name)
    form.addTextButton(line, nil, "Setup", function() setCurrentDevice(device) end)
  end
end

local function parseChoiceValues(data, offset)
  -- Split a table of byte values (string) with ; separator into a table
  local values = {}
  local opt = ''
  local b = data[offset]
  while b ~= 0 do
    if b == 59 then -- ';'
      print("Choice Value: " .. opt)
      values[#values + 1] = { opt, #values }
      opt = ''
    else
      opt = opt .. string.char(b)
    end
    offset = offset + 1
    b = data[offset]
  end
  print("Choice Value: " .. opt)
  values[#values + 1] = { opt, #values }
  return values, offset + 1, collectgarbage("collect")
end

local function parseParameterInfoMessage(data)
  local fieldId = (fieldPopup and fieldPopup.id) or loadQ[#loadQ]
  if data[2] ~= deviceId or data[3] ~= fieldId then
    fieldData = {}
    fieldChunk = 0
    return
  end
  local field = fields[fieldId]
  local chunksRemain = data[4]
  if not field or (chunksRemain ~= expectChunksRemain and #fieldData ~= 0) then
    return
  end
  expectChunksRemain = chunksRemain - 1
  for i = 5, #data do
    fieldData[#fieldData + 1] = data[i]
  end
  if chunksRemain > 0 then
    fieldChunk = fieldChunk + 1
  else
    loadQ[#loadQ] = nil
    if #fieldData > 3 then
      local offset
      field.id = fieldId
      field.parent = (fieldData[1] ~= 0) and fieldData[1] or nil
      field.type = fieldData[2] & 0x7f
      field.hidden = (fieldData[2] & 0x80) or nil
      field.name, offset = parseString(fieldData, 3, field.name)
      print("Field: " .. field.name .. ", Type: " .. field.type)

      while currentParent ~= nil and field.parent ~= currentParent.id do
        form.endExpansionPanel()
        currentParent = currentParent.parent
      end

      if field.type == 9 then
        field.values, offset = parseChoiceValues(fieldData, offset)
        field.value = fieldData[offset]
        field.unit = parseString(fieldData, offset + 4)
        local line = form.addLine(field.name)
        form.addChoiceField(line, nil, field.values, function() return field.value end, function(value) field.value = value crossfire.pushFrame(0x2D, { deviceId, handsetId, field.id, value }) end)
      elseif field.type == 11 then
        form.beginExpansionPanel(field.name)
        currentParent = field
      end

      --if field.min == 0 then field.min = nil end
      --if field.max == 0 then field.max = nil end
    end

    fieldChunk = 0
    fieldData = {}
  end
end

local function wakeup(widget)
  local time = os.clock()
  while true do
    command, data = crossfire.popFrame()
    if command == nil then
      break
    elseif command == 0x29 then
      parseDeviceInfoMessage(data)
    elseif command == 0x2B then
      parseParameterInfoMessage(data)
      if #loadQ > 0 then
        fieldTime = 0 -- request next chunk immediately
        --elseif fieldPopup then
        --  fieldTime = time + fieldPopup.timeout
      end
      --elseif command == 0x2D then
      --  parseElrsV1Message(data)
      --elseif command == 0x2E then
      --  parseElrsInfoMessage(data)
    end
  end

  --if fieldPopup then
  --  if time > fieldTime and fieldPopup.status ~= 3 then
  --    crossfire.pushFrame(0x2D, { deviceId, handsetId, fieldPopup.id, 6 }) -- lcsQuery
  --    fieldTime = time + fieldPopup.timeout
  --  end
  --else
  if time > devicesRefreshTime and deviceId == nil then
    devicesRefreshTime = time + 1 -- 1s
    crossfire.pushFrame(0x28, { 0x00, 0xEA })
  --elseif time > linkstatTime then
  --  if not isElrsTx and #loadQ == 0 then
  --    goodBadPkt = ""
  --  else
  --    crossfire.pushFrame(0x2D, { deviceId, handsetId, 0x0, 0x0 }) -- request linkstat
  --  end
  --  linkstatTime = time + 1
  elseif time > fieldTime and deviceId ~= nil then
    if #loadQ > 0 then
      crossfire.pushFrame(0x2C, { deviceId, handsetId, loadQ[#loadQ], fieldChunk })
      fieldTime = time + 0.5
    end
  end
end

local function init()
  system.registerElrsProtocol({configure={name=name, create=create, wakeup=wakeup}})
end

return {init=init}
