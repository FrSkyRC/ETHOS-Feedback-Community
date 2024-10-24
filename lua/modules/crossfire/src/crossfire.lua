-- Express LRS Module
crossfire = {}

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


if crsf.getSensor ~= nil then
    local sensor = crsf.getSensor()
    crossfire.popFrame = function() return sensor:popFrame() end
    crossfire.pushFrame = function(x,y) return sensor:pushFrame(x,y) end
else
    crossfire.popFrame = function() return crsf.popFrame() end
    crossfire.pushFrame = function(x,y) return crsf.pushFrame(x,y) end
end

function crossfire.pauseTelemetry(state)
        if crsf.getSensor ~= nil then
                CRSF_PAUSE_TELEMETRY = state
                ELRS_PAUSE_TELEMETRY = state
        end
end


function crossfire.create()
        devices = {}
        deviceId = nil
        fieldPopup = nil
        currentParent = nil
        currentExpansionPanel = nil
        crossfire.pauseTelemetry(true)
              
        return {}
end

function crossfire.close()
      crossfire.pauseTelemetry(false)
end


local function createDevice(id, name, fieldsCount)
        local device = {id = id, name = name, fieldsCount = fieldsCount, timeout = 0}
        return device
end

local function getDevice(name)
        for i = 1, #devices do if devices[i].name == name then return devices[i] end end
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
        for i = 0, size - 1 do result = (result << 8) + data[offset + i] end
        return result
end

local function setCurrentDevice(device)
        deviceId = device.id
        fields = {}
        fieldsCount = device.fieldsCount
        for i = 1, device.fieldsCount do fields[i] = {} end
        loadQ = {}
        for fieldId = fieldsCount, 1, -1 do loadQ[#loadQ + 1] = fieldId end
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

local function parseParameterInfoMessage(data)
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
                        local offset
                        field.id = fieldId
                        field.parent = fieldData[1]
                        field.type = fieldData[2] & 0x7f
                        field.hidden = fieldData[2] & 0x80
                        field.name, offset = parseString(fieldData, 3, field.name)
                        -- print("Field: " .. field.name .. ", Type: " .. field.type)

                        if currentParent ~= nil and field.parent ~= currentParent.id then
                                currentExpansionPanel = nil
                                currentParent = nil
                        end

                        if field.type == 9 then
                                field.values, offset = parseChoiceValues(fieldData, offset)
                                field.value = fieldData[offset]
                                field.unit = parseString(fieldData, offset + 4)
                                if field.widget == nil then
                                        local line = form.addLine(field.name, currentExpansionPanel)
                                        field.widget = form.addChoiceField(line, nil, field.values, function()
                                                return field.value
                                        end, function(value)
                                                field.value = value
                                                crossfire.pushFrame(0x2D, {deviceId, handsetId, field.id, value})
                                        end)
                                end
                        elseif field.type == 13 then
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
                                                                                crossfire.pushFrame(0x2D, {deviceId, handsetId, field.id, 4}) -- lcsConfirmed
                                                                                fieldTimeout = os.time() + field.timeout / 100 -- we are expecting an immediate response
                                                                                field.status = 4
                                                                        end
                                                                }, {label = "Cancel"}
                                                        })
                                                else
                                                        field.dialog:buttons({
                                                                {
                                                                        label = "Cancel",
                                                                        action = function()
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
                                        field.widget = form.addTextButton(line, nil, field.name, function()
                                                if field.status < 4 then
                                                        field.status = 1
                                                        crossfire.pushFrame(0x2D, {deviceId, handsetId, field.id, field.status})
                                                        fieldPopup = field
                                                        field.dialog = form.openDialog(field.name, field.info, {
                                                                {
                                                                        label = "Cancel",
                                                                        action = function()
                                                                                fieldPopup = nil
                                                                                return true
                                                                        end
                                                                }
                                                        })
                                                end
                                        end)
                                end
                        elseif field.type == 12 then
                                field.value, offset = parseString(fieldData, offset)
                                if field.widget == nil and field.hidden == 0 then
                                        local line = form.addLine(field.name, currentExpansionPanel)
                                        field.widget = form.addStaticText(line, nil, field.value)
                                end
                        elseif field.type == 11 then
                                currentExpansionPanel = form.addExpansionPanel(field.name)
                                currentParent = field
                        else
                                -- print("Not implemented!")
                        end
                end

                fieldChunk = 0
                fieldData = {}
        end
end

function crossfire.wakeup(widget)
 
        if lcd.hasFocus() or lcd.isVisible() then
                crossfire.pauseTelemetry(true)
        else
                crossfire.pauseTelemetry(false)
        end

  
        local time = os.clock()
        while true do
        
                command, data = crossfire.popFrame()
                if command == nil then
                        break
                elseif command == 0x29 then
                        parseDeviceInfoMessage(data)
                        menuDepth = 0
                elseif command == 0x2B then
                        menuDepth = 1
                        parseParameterInfoMessage(data)
                        if #loadQ > 0 or expectChunksRemain >= 0 then
                                fieldTime = 0 -- request next chunk immediately
                        elseif fieldPopup then
                                fieldTime = time + fieldPopup.timeout / 100
                        end
                        
                end
        end

        if fieldPopup then        
                if time > fieldTime and fieldPopup.status ~= 3 then
                              
                        crossfire.pushFrame(0x2D, {deviceId, handsetId, fieldPopup.id, 6}) -- lcsQuery
                        fieldTime = time + fieldPopup.timeout / 100
                end
        elseif time > devicesRefreshTime and deviceId == nil then

                devicesRefreshTime = time + 1 -- 1s
                crossfire.pushFrame(0x28, {0x00, 0xEA})

        elseif time > fieldTime and deviceId ~= nil then
                if #loadQ > 0 then
                             
                        crossfire.pushFrame(0x2C, {deviceId, handsetId, loadQ[#loadQ], fieldChunk})
                        fieldTime = time + 0.5
                end
        end

end

function crossfire.event(widget, category, value, x, y)
        
        if menuDepth == 1 then
                if category == EVT_CLOSE then
                        form.clear()
                        devices = {}
                        deviceId = nil
                        fieldPopup = nil
                        currentParent = nil
                        currentExpansionPanel = nil
                        return true
                end
                if category == 0 and value == 35 then
                        form.clear()
                        devices = {}
                        deviceId = nil
                        fieldPopup = nil
                        currentParent = nil
                        currentExpansionPanel = nil
                        return true
                end
        end
        crossfire.pauseTelemetry(false)
        return false
end

return crossfire

