PROTOCOL_NAME = "protocol_fbus"
assert(loadfile("config/config.lua"))()

local series65Parameters = {
  { fieldFunction = CreateChoiceField, fieldName = STR("WorkingMode"), pageAddress = 0x40, extraInfo = {valuePairs = {{"Angle mode", 0}, {"Range mode", 1}, {"Rotate mode", 2}}, } },
  { fieldFunction = CreateNumberField, fieldName = STR("XActMaxAngle"), pageAddress = 0x41, extraInfo = {min = 0, max = 359, suffix = " Degree"} },
}

local series65build = false
local writeDialog = nil
local saveStep = 0
local sensor = nil
local exitRequested = false -- system.exit() is called from the page wakeup

local xActAppIdPairs = {{"6800", 0}, {"6801", 1}, {"6802", 2}, {"6803", 3}, {"6804", 4}, {"6805", 5}, {"6806", 6}, {"6807", 7},
                        {"6808", 8}, {"6809", 9}, {"680A", 10}, {"680B", 11}, {"680C", 12}, {"680D", 13}, {"680E", 14}, {"680F", 15},}

local parameters = {
  { fieldFunction = CreatePhyIdField, fieldName = STR("PhyID"), pageAddress = 0x00, defaultValue = 10, extraInfo = {} },
  { fieldFunction = CreateAppIdField, fieldName = STR("AppID"), pageAddress = 0x01, extraInfo = {valuePairs = xActAppIdPairs} },
  { fieldFunction = CreateNumberField, fieldName = STR("Firmware"), pageAddress = 0xFE, extraInfo = {min = 0, max = 255, disable = true, text = function(value)
    return math.floor(value / 10) .. "." .. value % 10 .. ".0"
  end} },
  { fieldFunction = CreateNumberField, fieldName = STR("DataRate"), pageAddress = 0x02, defaultValue = 100, extraInfo = {min = 10, max = 60000, suffix = "ms"}},
  { fieldFunction = CreateChoiceField, fieldName = STR("XActRange"), pageAddress = 0x04, extraInfo = {valuePairs = {{"120 Degree", 0}, {"90 Degree", 1}, {"180 Degree", 2}}, } },
  { fieldFunction = CreateChoiceField, fieldName = STR("Direction"), pageAddress = 0x05, extraInfo = {valuePairs = {{"Clockwise", 0}, {"Anticlockwise", 1}}} },
  { fieldFunction = CreateChoiceField, fieldName = STR("PWMPulseType"), pageAddress = 0x06, extraInfo = {valuePairs = {{"1500us", 0}, {"760us", 1}}} },
  { fieldFunction = CreateNumberField, fieldName = STR("Channel"), pageAddress = 0x07, valueWrite = function(value)
    return value - 1
  end, valueRead = function(value)
    return value + 1
  end, extraInfo = {min = 1, max = 24, prefix = "CH"}},
  { fieldFunction = CreateNumberField, fieldName = STR("Center"), pageAddress = 0x08, valueRead = function(value)
    value = value & 0xFF
    return value > 127 and value - 256 or value
  end, valueWrite = function(value)
    return value & 0xFF
  end, extraInfo = {min = -125, max = 125}},
  { fieldFunction = CreateNumberField, fieldName = STR("HoldingStrength"), pageAddress = 0x11, getValue = function(value)
    return value ~= nil and value or 10
  end, setValue = function(param, newValue)
    param.value = newValue
    param.state = FieldState.DIRTY
    for _, p in ipairs(Params) do
      if p.pageAddress == 0x12 then
        p.value = 10
        p.state = FieldState.DIRTY
        break
      end
    end
  end, extraInfo = {min = 4, max = 15, prec = 1, step = 1} },
  { fieldFunction = CreateNumberField, fieldName = STR("OperationSmoothing"), pageAddress = 0x13, extraInfo = {min = 0, max = 50} },
  { fieldFunction = CreateNumberField, fieldName = STR("Deadband"), pageAddress = 0x21, extraInfo = {min = 0, max = 90} },
}

-- Sends the save command, once the changed values reached the device, in a progress dialog which can be cancelled.
-- When it is done, a toast (since Ethos 26.2.0, before the dialog shows the message). onSaved is called then.
local function save(onSaved)
  print("Save to flash")
  saveStep = 0
  writeDialog = form.openWaitDialog({title = STR("Saving"), message = STR("WritingSaveCommand"), progress = true,
                                     closeLabel = STR("Cancel"), wakeup = function()
    if saveStep == 0 then
      -- the changed values must reach the device before it saves them
      if not ConfigHasPendingWrites() and SensorWriteParameter({sensor = sensor}, 0x15, 7) then
        saveStep = 1
        writeDialog:value(50)
      end
    elseif saveStep == 1 then
      if SensorWriteParameter({sensor = sensor}, 0x30, 0) then
        ConfigUnsaved = false
        saveStep = 2
        print("Save to flash: done")
        if system.toast ~= nil then
          writeDialog:close()
          writeDialog = nil
          system.toast(STR("SaveSuccessfully"))
        else
          writeDialog:value(100)
          writeDialog:message(STR("SaveSuccessfully"))
        end
        if onSaved ~= nil then
          onSaved()
        end
      end
    end
  end, close = function()
    -- closed by the user (Cancel)
    if saveStep < 2 then
      print("Save to flash: cancelled")
    end
    writeDialog = nil
  end})
end

local function create(module, appId)
  series65build = false
  exitRequested = false

  local appRange = {appIdStart = 0x6800, appIdEnd = 0x680F, module = 0xFFFF}

  sensor = sport.getSensor(appRange)

  BuildConnectionChoice(appRange)

  if appId and appId ~= 0xFFFF then
    print("Receive appId from ETHOS: ", string.format("%04X", appId))
    sensor:appId(appId)
    ConnectedAppId = appId
  end
  if module and module ~= 0xFF then
    print("Receive module from ETHOS: ", module)
    sensor:module(module)
  end

  local line = form.addLine("")
  form.addTextButton(line, nil, STR("SaveToFlash"), function()
    save()
    return 0
  end)

  Params = {}
  for _, p in ipairs(parameters) do
    Params[#Params + 1] = p
  end

  ReceiveValueHandler = function ()
    if not series65build then
      for _, parameter in ipairs(Params) do
        if parameter.pageAddress == 0xFE then
          print("Firmware: ", parameter.value)
          if parameter.value ~= nil and type(parameter.value) == "number" and parameter.state == FieldState.RECEIVED then
            if parameter.value >= 40 then
              print("Build 65s form")
              for _, extP in ipairs(series65Parameters) do
                extP.value = nil
                extP.state = FieldState.INIT
                extP.fieldFunction(extP)
                Params[#Params + 1] = extP
              end
            end
            series65build = true
          elseif parameter.state == FieldState.SKIPPED then
            series65build = true
          end
          return
        end
      end
    end
  end

  ConfigCreate()

  -- 0x12 is paired with Holding strength (0x11); always written as 10 when 0x11 changes
  Params[#Params + 1] = { pageAddress = 0x12, value = 10, state = FieldState.RECEIVED }

  return {sensor = sensor, needIdle = false}
end

local function wakeup(data)
  if exitRequested then
    exitRequested = false
    system.exit()
    return
  end
  ConfigWakeup(data)
end

-- Leaving the page (back arrow, RTN) with changes not saved to flash: they would be lost when the servo is powered off
local function event(data, category, value, x, y)
  if category == EVT_CLOSE and ConfigHasUnsavedChanges() then
    print("Unsaved changes, confirm before leaving")
    form.openDialog({title = STR("UnsavedChanges"), message = STR("SaveBeforeLeaving"), buttons = {
      {label = STR("Save"), action = function()
        save(function()
          if writeDialog ~= nil then
            -- the dialog showing the message (no toast before Ethos 26.2.0)
            writeDialog:close()
            writeDialog = nil
          end
          exitRequested = true
        end)
        return true
      end},
      {label = STR("DontSave"), action = function()
        print("Leave without saving")
        exitRequested = true
        return true
      end},
      {label = STR("Cancel"), action = function()
        return true
      end},
    }})
    return true
  end
  return false
end

return {create = create, name = "XAct", wakeup = wakeup, event = event, close = ConfigClose}
