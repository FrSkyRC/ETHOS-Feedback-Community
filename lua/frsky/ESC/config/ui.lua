-- FrSky lua device config UI fields and the shared parameter state machine.
-- Protocol files supply ProtocolPoll / ProtocolRead / ProtocolSend / ProtocolReset.
---@diagnostic disable: unused-local

FieldState = {
  INIT = 1,
  IDLE = 2,
  RECEIVED = 3,
  DIRTY = 4,
  SKIPPED = 5,
}

ConnectionType = {
  RF = 1,
  SPort = 2,
}
PhysIdTable = {
  0x00, 0xA1, 0x22, 0x83, 0xE4, 0x45, 0xC6, 0x67,
  0x48, 0xE9, 0x6A, 0xCB, 0xAC, 0x0D, 0x8E, 0x2F,
  0xD0, 0x71, 0xF2, 0x53, 0x34, 0x95, 0x16, 0xB7,
  0x98, 0x39, 0xBA, 0x1B, 0x7C, 0xDD, 0x5E, 0xFF
};
PHY_ID_NOT_SET = 0x01

LastRollCalledTime = 0
WorkingConnectionType = ConnectionType.RF
SportConnection = nil
RollCalledPhyIdIndex = 0
ConnectedPhyId = PHY_ID_NOT_SET
ConnectedAppId = 0
AppIdStart = 0
AppIdEnd = 0
LastPolledPhyId = PHY_ID_NOT_SET
ResponsePhyId = PHY_ID_NOT_SET
Params = {}
ReceiveValueHandler = nil

function BuildConnectionChoice(appIdRange)
  if appIdRange ~= nil then
    AppIdStart = appIdRange.appIdStart
    AppIdEnd = appIdRange.appIdEnd
  end
  local line = form.addLine(STR and STR("ConnectionType") or "Connection Type")
  local valuePairs = {
    {STR and STR("RFModule") or "RF module", ConnectionType.RF},
    {STR and STR("SPortInterface") or "S.Port interface", ConnectionType.SPort},
  }
  local field = form.addChoiceField(line, nil, valuePairs, function()
    return WorkingConnectionType
  end, function(value)
    WorkingConnectionType = value
    if (WorkingConnectionType == ConnectionType.RF) then
      if SportConnection ~= nil then
        -- SportConnection:destroy()
      end
      SportConnection = nil
      print("RF module is activated")
    else
      SportConnection = serial.open("sport", SportInterfaceBandrate, "8N1", true)
      if SportConnection ~= nil then
        print("S.Port interface is activated")
      else
        print("Failed to activate S.Port interface")
      end
    end
  end)
end

local function getValue(param)
  if param.getValue ~= nil then
    return param.getValue(param.value)
  end

  if param.value == nil then
    return param.defaultValue ~= nil and param.defaultValue or 0
  else
    if param.valueIndex then
      return (param.value >> ((param.valueIndex - 1) * 8)) & 0xFF
    else
      return param.value
    end
  end
end

local function setValue(param, newValue)
  if param.setValue ~= nil then
    param.setValue(param, newValue)
    return
  end

  if param.valueIndex then
    local shift = (param.valueIndex - 1) * 8
    param.value = param.value & ~(0xFF << shift) | (newValue << shift)
  else
    param.value = newValue
  end
  param.state = FieldState.DIRTY
end

--[[
  CreateChoiceField(param)
    param (table) - { fieldFunction, fieldName, pageAddress, getValue, setValue, valueIndex, extraInfo }
      fieldFunction (function) - Necessary. The function creates the field
      fieldName (string) - Necessary. The field name displays at the begining
      pageAddress (number) - Necessary.
      getValue (function) - Optional. Only needed when the field requires a special getValue handler
      setValue (function) - Optional. Only needed when the field requires a special setValue handler
      valueIndex (number) - Optional. Only needed when the field doesn't need the whole received value. Normally would be 1 ~ 3
      defaultValue (number) - Optional. Only needed when the field hasn't been read yet. To set the value which should be displayed
      valueWrite(function) - Optional. Only needed when the field needs a special value process before writing
      valueRead(function) - Optional. Only needed when the field needs a special value process before reading
      extraInfo (table) - Necessary. extraInfo = { valuePairs }
      valuePairs (table) - Necessary. The pairs for choice field to map value with test. Should be in form like {{0, "value1"}, {1, "value2"}, ...}

      The following field will be added by code automaticlly
        value (number) - The current value for the address. 3 bytes
        state (number) - The field state, see FieldState
--]]
function CreateChoiceField(param)
  if param.extraInfo == nil or param.extraInfo.valuePairs == nil then
    print("Field create failed (" .. param.fieldName .. ") - Missing valuePairs")
    return
  end

  local line = form.addLine(param.fieldName)
  local field = form.addChoiceField(line, nil, param.extraInfo.valuePairs, function()
    return getValue(param)
  end, function(value)
    return setValue(param, value)
  end)
  field:enable(false)
  param.field = field
end

--[[
  CreateNumberField(param)
    param (table) - { fieldFunction, fieldName, pageAddress, getValue, setValue, valueIndex, extraInfo }
      fieldFunction (function) - Necessary. The function creates the field
      fieldName (string) - Necessary. The field name displays at the begining
      pageAddress (number) - Necessary.
      getValue (function) - Optional. Only needed when the field requires a special getValue handler
      setValue (function) - Optional. Only needed when the field requires a special setValue handler
      valueIndex (number) - Optional. Only needed when the field doesn't need the whole received value. Normally would be 1 ~ 3
      defaultValue (number) - Optional. Only needed when the field hasn't been read yet. To set the value which should be displayed
      valueWrite(function) - Optional. Only needed when the field needs a special value process before writing
      valueRead(function) - Optional. Only needed when the field needs a special value process before reading
      extraInfo (table) - Necessary. extraInfo = { min, max, step, suffix, prefix, prec, text }
        min (number) - Necessary. Min value for the number edit
        max (number) - Necessary. Max value for the number edit
        step (number) - Optional. Step during the number edit
        suffix (string) - Optional. Display suffix for the number edit
        prefix (string) - Optional. Display prefix for the number edit
        prec (number) - Optional. Represent the display's resolution
        text (function) - Optional. Custom function to get display text from a value.

      The following field will be added by code automaticlly
        value (number) - The current value for the address. 3 bytes
        state (number) - The field state, see FieldState
--]]
function CreateNumberField(param)
  if param.extraInfo == nil or param.extraInfo.min == nil or param.extraInfo.max == nil then
    print("Field create failed (" .. param.fieldName .. ") - Missing min/max")
    return
  end

  local line = form.addLine(param.fieldName)
  local field = form.addNumberField(line, nil, param.extraInfo.min, param.extraInfo.max, function()
    return getValue(param)
  end, function(value)
    return setValue(param, value)
  end)
  field:enableInstantChange(false)
  if param.extraInfo.step then
    field:step(param.extraInfo.step)
  end
  if param.extraInfo.suffix then
    field:suffix(param.extraInfo.suffix)
  end
  if param.extraInfo.prefix then
    field:prefix(param.extraInfo.prefix)
  end
  if param.extraInfo.prec then
    field:decimals(param.extraInfo.prec)
  end
  if param.extraInfo.text then
    field:text(param.extraInfo.text)
  end
  if field.defaultStep then
    if param.extraInfo.defaultStep then
      field:defaultStep(param.extraInfo.defaultStep)
    end
  end
  field:enable(false)
  param.field = field
end

--[[
  CreateTextButton(param)
    param (table) - { fieldFunction, fieldName, pageAddress, getValue, setValue, valueIndex, extraInfo }
      fieldFunction (function) - Necessary. The function creates the field
      fieldName (string) - Necessary. The field name displays at the begining
      pageAddress (number) - Necessary.
      getValue (function) - Optional. Only needed when the field requires a special getValue handler
      setValue (function) - Optional. Only needed when the field requires a special setValue handler
      valueIndex (number) - Optional. Only needed when the field doesn't need the whole received value. Normally would be 1 ~ 3
      valueWrite(function) - Optional. Only needed when the field needs a special value process before writing
      valueRead(function) - Optional. Only needed when the field needs a special value process before reading
      extraInfo (table) - Necessary. extraInfo = { buttonText }
        buttonText (string) - Necessary. The text displays on the button

      The following field will be added by code automaticlly
        value (number) - The current value for the address. 3 bytes
        state (number) - The field state, see FieldState
--]]
function CreateTextButton(param)
  if param.extraInfo == nil or param.extraInfo.buttonText == nil then
    print("Field create failed (" .. param.fieldName .. ") - Missing buttonText")
    return
  end

  local line = form.addLine(param.fieldName)
  local field = form.addTextButton(line, nil, param.extraInfo.buttonText, function()
    setValue(param)
    return 0
  end)
  field:enable(false)
  param.field = field
end

--[[
  CreateStaticText(param)
    param (table) - { fieldFunction, fieldName, pageAddress, getValue, valueIndex, extraInfo }
      fieldFunction (function) - Necessary. The function creates the field
      fieldName (string) - Necessary. The field name displays at the begining
      pageAddress (number) - Necessary.
      getValue (function) - Optional. Only needed when the field requires a special getValue handler
      valueIndex (number) - Optional. Only needed when the field doesn't need the whole received value. Normally would be 1 ~ 3
      defaultValue (number) - Optional. Only needed when the field hasn't been read yet. To set the value which should be displayed
      valueWrite(function) - Optional. Only needed when the field needs a special value process before writing
      valueRead(function) - Optional. Only needed when the field needs a special value process before reading
      extraInfo (table) - Optional. extraInfo = { }

      The following field will be added by code automaticlly
        value (number) - The current value for the address. 3 bytes
        state (number) - The field state, see FieldState
--]]
function CreateStaticText(param)
  local line = form.addLine(param.fieldName)
  form.addStaticText(line, nil, function()
    return getValue(param)
  end)
end

local appIdPairs = {{"0000", 0}, {"0001", 1}, {"0002", 2}, {"0003", 3}, {"0004", 4}, {"0005", 5}, {"0006", 6}, {"0007", 7},
                    {"0008", 8}, {"0009", 9}, {"000A", 10}, {"000B", 11}, {"000C", 12}, {"000D", 13}, {"000E", 14}, {"000F", 15},}

function CreateAppIdField(param)
  param.isAppId = true
  if param.extraInfo == nil then
    param.extraInfo = {}
  end
  if param.extraInfo.valuePairs == nil then
    param.extraInfo.valuePairs = appIdPairs
  end
  CreateChoiceField(param)
end

local phyIdPairs = {{"00", 0}, {"01", 1}, {"02", 2}, {"03", 3}, {"04", 4}, {"05", 5}, {"06", 6}, {"07", 7},
                    {"08", 8}, {"09", 9}, {"0A", 10}, {"0B", 11}, {"0C", 12}, {"0D", 13}, {"0E", 14}, {"0F", 15},
                    {"10", 16}, {"11", 17}, {"12", 18}, {"13", 19}, {"14", 20}, {"15", 21}, {"16", 22}, {"17", 23},
                    {"18", 24}, {"19", 25}, {"1A", 26},}

function CreatePhyIdField(param)
  if param.extraInfo == nil then
    param.extraInfo = {}
  end
  param.extraInfo.valuePairs = phyIdPairs
  CreateChoiceField(param)
end

local requestInProgress = false
local lastRquestTime = 0

function ConfigCreate()
  print("Enter config page, InitPage()")
  requestInProgress = false
  lastRquestTime = 0
  WorkingConnectionType = ConnectionType.RF
  SportConnection = nil
  RollCalledPhyIdIndex = 0
  ConnectedPhyId = PHY_ID_NOT_SET
  ConnectedAppId = 0
  LastPolledPhyId = PHY_ID_NOT_SET
  ResponsePhyId = PHY_ID_NOT_SET
  if ProtocolReset ~= nil then
    ProtocolReset()
  end

  for index, parameter in pairs(Params) do
    if parameter.fieldFunction == nil then
      print("Missing field function!")
    elseif parameter.fieldName == nil then
      print("Missing field name")
    elseif parameter.pageAddress == nil then
      print("Missing field page address")
    else
      parameter.value = nil
      parameter.state = FieldState.INIT
      parameter.fieldFunction(parameter)
    end
  end
end

function SensorIdle(data, idle)
  if WorkingConnectionType == ConnectionType.SPort and SportConnection ~= nil then
    ProtocolSend(idle and 0x21 or 0x20, 0, 0, 0, 0)
    return true
  else
    return data.sensor:idle(idle)
  end
end

function SensorRequestParameter(data, pageAddress)
  if WorkingConnectionType == ConnectionType.SPort and SportConnection ~= nil then
    ProtocolSend(0x30, pageAddress & 0xFF, 0, 0, 0)
    return true
  else
    return data.sensor:requestParameter(pageAddress)
  end
end

function SensorWriteParameter(data, pageAddress, value)
  if WorkingConnectionType == ConnectionType.SPort and SportConnection ~= nil then
    ProtocolSend(0x31, pageAddress & 0xFF, value & 0xFF, (value >> 8) & 0xFF, (value >> 16) & 0xFF)
    return true
  else
    return data.sensor:writeParameter(pageAddress, value)
  end
end

function SensorGetParameter(data)
  if WorkingConnectionType == ConnectionType.SPort and SportConnection ~= nil then
    local frames = ProtocolRead()
    if frames == nil then
      return nil
    end
    for i = 1, #frames do
      local frame = frames[i]
      if frame.prim == 0x32 and frame.appId == ConnectedAppId then
        return frame.value
      end
    end
    return nil
  else
    return data.sensor:getParameter()
  end
end

function ConfigWakeup(data)
  if Params == nil or data == nil then
    return
  end

  if WorkingConnectionType == ConnectionType.SPort and SportConnection ~= nil then
    ResponsePhyId = LastPolledPhyId
    if os.clock() - LastRollCalledTime > RollCalledInterval and (ConnectedPhyId == PHY_ID_NOT_SET or requestInProgress) then
      LastRollCalledTime = os.clock()
      local calledPhyId = ConnectedPhyId

      if calledPhyId == PHY_ID_NOT_SET then
        RollCalledPhyIdIndex = RollCalledPhyIdIndex + 1
        if RollCalledPhyIdIndex > 28 then
          RollCalledPhyIdIndex = 1
        end
        calledPhyId = PhysIdTable[RollCalledPhyIdIndex]
      end
      LastPolledPhyId = calledPhyId
      ProtocolPoll(calledPhyId)
    end

    if ConnectedAppId == 0 then
      local frames = ProtocolRead()
      if frames == nil then
        return
      end
      for i = 1, #frames do
        local frame = frames[i]
        if frame.discover and frame.appId >= AppIdStart and frame.appId <= AppIdEnd then
          ConnectedAppId = frame.appId
          ConnectedPhyId = frame.physId
          print("Connected appId: 0x", string.format("%04X", ConnectedAppId))
          print("Connected phyId: 0x", string.format("%02X", ConnectedPhyId))
          break
        end
      end
    end
  else
    if data.sensor:appId() == 0xFFFF then
      local frame = data.sensor:popFrame()
      if frame == nil then
        return
      end
      data.sensor:module(frame:module())
      data.sensor:band(frame:band())
      data.sensor:rx(frame:rx())
      data.sensor:appId(frame:appId())
    end
  end

  if data.needIdle == nil or data.needIdle then
    for index, parameter in pairs(Params) do
      if parameter.state == FieldState.INIT then
        if SensorIdle(data, true) then
          parameter.state = FieldState.IDLE
        end
        return
      end
    end
  else
    for index, parameter in pairs(Params) do
      if parameter.state == FieldState.INIT then
        parameter.state = FieldState.IDLE
      end
    end
  end

  if requestInProgress then
    local receivedValue = SensorGetParameter(data)
    if receivedValue ~= nil then
      print("sensor:getParameter(): 0x", string.format("%08X", receivedValue))
      local pageAddress = receivedValue & 0xFF
      local value = receivedValue >> 8
      for index, parameter in pairs(Params) do
        if parameter.pageAddress == pageAddress then
          local valueRead = value
          if parameter.valueRead ~= nil then
            valueRead = parameter.valueRead(valueRead)
          end
          parameter.value = valueRead
          parameter.state = FieldState.RECEIVED
          parameter.tryTimes = nil
          if parameter.field ~= nil then
            if (parameter.extraInfo == nil) or (not parameter.extraInfo.disable) then
              parameter.field:enable(true)
            else
              lcd.invalidate()
            end
          end
        end
      end
      if ReceiveValueHandler ~= nil then
        ReceiveValueHandler()
      end
      requestInProgress = false
    elseif os.clock() - lastRquestTime > 1 then
      print("Request timeout")
      requestInProgress = false
    end
  else
    for index, parameter in pairs(Params) do
      if parameter.state == FieldState.IDLE then
        if SensorRequestParameter(data, parameter.pageAddress) then
          print("sensor:requestParameter(0x" .. string.format("%02X", parameter.pageAddress) .. ")")
          requestInProgress = true
          lastRquestTime = os.clock()
          if parameter.tryTimes == nil then
            parameter.tryTimes = 1
          else
            parameter.tryTimes = parameter.tryTimes + 1
          end
          if parameter.tryTimes > 4 then
            parameter.state = FieldState.SKIPPED
          end
          return
        end
      elseif parameter.state == FieldState.DIRTY then
        local valueWrite
        if parameter.valueWrite ~= nil then
          valueWrite = parameter.valueWrite(parameter.value)
        else
          local D1 = parameter.value & 0xFF
          local D2 = (parameter.value >> 8) & 0xFF
          local D3 = (parameter.value >> 16) & 0xFF
          valueWrite = D1 + D2 * 256 + D3 * 256 * 256
        end
        if SensorWriteParameter(data, parameter.pageAddress, valueWrite) then
          print("sensor:writeParameter(0x" .. string.format("%02X", parameter.pageAddress) .. "): " .. string.format("%X", valueWrite))
          if parameter.isAppId ~= nil and parameter.isAppId then
            if WorkingConnectionType == ConnectionType.SPort and SportConnection ~= nil then
              ConnectedAppId = (ConnectedAppId & 0xFFF0) | parameter.value
            else
              local oldAppId = data.sensor:appId()
              data.sensor:appId(oldAppId & 0xFFF0 | parameter.value)
            end
          end
          requestInProgress = false
          parameter.state = FieldState.IDLE
          return
        end
      end
    end
  end
end

function ConfigClose(data)
  if data ~= nil and (data.needIdle == nil or data.needIdle) then
    SensorIdle(data, false)
  end
end
