-- FrSky lua device config protocol: F.Bus over Sport connector (RF / S.Port)
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
RollCalledInterval = 0.05 -- 50ms

LastRollCalledTime = 0
SportInterfaceBandrate = 460800
WorkingConnectionType = ConnectionType.RF
SportConnection = nil
RollCalledPhyIdIndex = 0
ConnectedPhyId = PHY_ID_NOT_SET
ConnectedAppId = 0
AppIdStart = 0
AppIdEnd = 0

local requestInProgress
local lastRquestTime
Params = {}
ReceiveValueHandler = nil

function ConfigCreate()
  print("Enter config page, InitPage()")
  requestInProgress = false
  lastRquestTime = 0
  WorkingConnectionType = ConnectionType.RF
  SportConnection = nil
  RollCalledPhyIdIndex = 0
  ConnectedPhyId = PHY_ID_NOT_SET
  ConnectedAppId = 0

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

--[[
  SetupFBusFrame(...)
    Same as ETHOS ProtocolFBus::setupFBusFrame().
    Builds an F.Bus TX frame: 0x08 (FBUS_SPORT_START, not in CRC) + payload + CRC.
    CRC: crc += byte; crc += crc >> 8; crc &= 0xFF; then append (0xFF - crc).
    Payload: a table of bytes, or varargs of bytes
      (typically physId, primId, appIdLo, appIdHi, v0, v1, v2, v3).
    Returns a string for SportConnection:write().
    Example:
      SportConnection:write(SetupFBusFrame(calledPhyId, 0x10, 0, 0, 0, 0, 0, 0))
]]
function SetupFBusFrame(...)
  local data = type(...) == "table" and ... or {...}
  local crc = 0
  local frame = string.char(0x08)
  for i = 1, #data do
    local b = data[i]
    frame = frame .. string.char(b)
    crc = crc + b
    crc = crc + (crc >> 8)
    crc = crc & 0xFF
  end
  return frame .. string.char(0xFF - crc)
end

--[[
  ValidateFBusFrame(...)
    Inverse of SetupFBusFrame().
    Scans the whole received buffer for 10-byte F.Bus frames
    (0x08 start, not in CRC, + 8-byte payload + CRC). The 0x08 may be at any offset,
    and one buffer may contain more than one valid frame.
    CRC: crc += byte; crc += crc >> 8; crc &= 0xFF; last byte must be (0xFF - crc).
    Buffer: a string, a table of bytes, or varargs of bytes.
    Returns a table of extracted frames, or nil if none is valid.
]]
function ValidateFBusFrame(...)
  local first = ...
  local data
  if type(first) == "string" then
    data = {}
    for i = 1, #first do
      data[i] = string.byte(first, i)
    end
  else
    data = type(first) == "table" and first or {...}
  end

  local frameLen = 10
  if #data < frameLen then
    return nil
  end

  local frames = {}
  local start = 1
  while start <= #data - frameLen + 1 do
    if data[start] == 0x08 then
      local crc = 0
      for i = start + 1, start + frameLen - 2 do
        local b = data[i]
        crc = crc + b
        crc = crc + (crc >> 8)
        crc = crc & 0xFF
      end
      if data[start + frameLen - 1] == (0xFF - crc) then
        local frame = {}
        for i = 1, frameLen do
          frame[i] = data[start + i - 1]
        end
        frames[#frames + 1] = frame
        start = start + frameLen
      else
        start = start + 1
      end
    else
      start = start + 1
    end
  end
  if #frames == 0 then
    return nil
  end
  return frames
end

function SensorIdle(data, idle)
  if WorkingConnectionType == ConnectionType.SPort and SportConnection ~= nil then
    SportConnection:write(SetupFBusFrame(ConnectedPhyId, idle and 0x21 or 0x20, ConnectedAppId & 0xFF, (ConnectedAppId >> 8) & 0xFF, 0, 0, 0, 0))
    SportConnection:flush()
    return true
  else
    return data.sensor:idle(idle)
  end
end

function SensorRequestParameter(data, pageAddress)
  if WorkingConnectionType == ConnectionType.SPort and SportConnection ~= nil then
    SportConnection:write(SetupFBusFrame(ConnectedPhyId, 0x30, ConnectedAppId & 0xFF, (ConnectedAppId >> 8) & 0xFF, pageAddress & 0xFF, 0, 0, 0))
    SportConnection:flush()
    return true
  else
    return data.sensor:requestParameter(pageAddress)
  end
end

function SensorWriteParameter(data, pageAddress, value)
  if WorkingConnectionType == ConnectionType.SPort and SportConnection ~= nil then
    SportConnection:write(SetupFBusFrame(ConnectedPhyId, 0x31, ConnectedAppId & 0xFF, (ConnectedAppId >> 8) & 0xFF, pageAddress & 0xFF, value & 0xFF, (value >> 8) & 0xFF, (value >> 16) & 0xFF))
    SportConnection:flush()
    return true
  else
    return data.sensor:writeParameter(pageAddress, value)
  end
end

function SensorGetParameter(data)
  if WorkingConnectionType == ConnectionType.SPort and SportConnection ~= nil then
    if SportConnection:empty() then
      return nil
    end

    local frame = SportConnection:read()
    if frame == nil then
      return nil
    end

    local buffer = {}
    for i = 1, #frame do
      buffer[i] = string.byte(frame, i)
    end
    local s = {}
    for i = 1, #buffer do
      s[i] = string.format("%02X", buffer[i])
    end
    print("S.Port connector received:", table.concat(s, " "))
    local frames = ValidateFBusFrame(buffer)
    if frames == nil then
      -- print("Invalid F.Bus frame")
      return nil
    end

    for i = 1, #frames do
      local frame = frames[i]
      local receivedAppId = frame[4] + (frame[5] << 8)
      if receivedAppId ~= ConnectedAppId then
        -- print("Received appId does not match connected appId")
      elseif frame[3] ~= 0x32 then
        -- print("Received frame is not a parameter request")
      else
        return frame[6] + (frame[7] << 8) + (frame[8] << 16) + (frame[9] << 24)
      end
    end
    return nil
  else
    return data.sensor:getParameter()
  end
end

function ConfigWakeup(data)
  -- Check page parameters
  if Params == nil or data == nil then
    return
  end

  -- Working with S.Port interface
  if WorkingConnectionType == ConnectionType.SPort and SportConnection ~= nil then
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
      SportConnection:write(SetupFBusFrame(calledPhyId, 0x10, 0, 0, 0, 0, 0, 0))
      SportConnection:flush()
    end

    -- Check the first frame
    if ConnectedAppId == 0 then
      if SportConnection:empty() then
        return
      end

      local frame = SportConnection:read()
      if frame == nil then
        return
      end

      local buffer = {}
      for i = 1, #frame do
        buffer[i] = string.byte(frame, i)
      end
      local s = {}
      for i = 1, #buffer do
        s[i] = string.format("%02X", buffer[i])
      end
      -- print("S.Port connector received:", table.concat(s, " "))
      local frames = ValidateFBusFrame(buffer)
      if frames == nil then
        -- print("Invalid F.Bus frame")
        return
      end
      for i = 1, #frames do
        local frame = frames[i]
        local receivedAppId = frame[4] + (frame[5] << 8)
        if receivedAppId < AppIdStart or receivedAppId > AppIdEnd then
          -- print("Received appId is out of range")
        else
          ConnectedAppId = receivedAppId
          print("Connected appId: 0x", string.format("%04X", ConnectedAppId))
          ConnectedPhyId = frame[2]
          print("Connected phyId: 0x", string.format("%02X", ConnectedPhyId))
          break
        end
      end
    end
  else
    -- Check the first frame
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

  -- Set idld mode if needed
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

  -- Read and process progress
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
            if (parameter.extraInfo.disable == nil) or (not parameter.extraInfo.disable) then
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

  -- Write and request progress
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
              local oldAppId = ConnectedAppId
              ConnectedAppId = oldAppId & 0xFFF0 | parameter.value
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
  if data.needIdle then
    SensorIdle(data, false)
  end
end
