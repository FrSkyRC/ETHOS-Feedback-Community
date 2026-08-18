assert(loadfile("config.lua"))()

local series65Parameters = {
  { fieldFunction = CreateChoiceField, fieldName = "Working mode", pageAddress = 0x40, extraInfo = {valuePairs = {{"Angle mode", 0}, {"Range mode", 1}, {"Rotate mode", 2}}, } },
  { fieldFunction = CreateNumberField, fieldName = "XAct max angle", pageAddress = 0x41, extraInfo = {min = 0, max = 359, suffix = " Degree"} },
}

local series65build = false
local writeDialog = nil
local lastSaveTime = 0
local saveStep = 0

local xActAppIdPairs = {{"6800", 0}, {"6801", 1}, {"6802", 2}, {"6803", 3}, {"6804", 4}, {"6805", 5}, {"6806", 6}, {"6807", 7},
                        {"6808", 8}, {"6809", 9}, {"680A", 10}, {"680B", 11}, {"680C", 12}, {"680D", 13}, {"680E", 14}, {"680F", 15},}

local parameters = {
  { fieldFunction = CreatePhyIdField, fieldName = "Physical Id", pageAddress = 0x00, defaultValue = 10, extraInfo = {} },
  { fieldFunction = CreateAppIdField, fieldName = "Application Id", pageAddress = 0x01, extraInfo = {valuePairs = xActAppIdPairs} },
  { fieldFunction = CreateNumberField, fieldName = "Firmware", pageAddress = 0xFE, extraInfo = {min = 0, max = 255, disable = true} },
  { fieldFunction = CreateNumberField, fieldName = "Data rate", pageAddress = 0x02, defaultValue = 100, extraInfo = {min = 10, max = 60000, suffix = "ms"}},
  { fieldFunction = CreateChoiceField, fieldName = "XAct range", pageAddress = 0x04, extraInfo = {valuePairs = {{"120 Degree", 0}, {"90 Degree", 1}, {"180 Degree", 2}}, } },
  { fieldFunction = CreateChoiceField, fieldName = "Direction", pageAddress = 0x05, extraInfo = {valuePairs = {{"Clockwise", 0}, {"Anticlockwise", 1}}} },
  { fieldFunction = CreateChoiceField, fieldName = "PWM pulse type", pageAddress = 0x06, extraInfo = {valuePairs = {{"1500us", 0}, {"760us", 1}}} },
  { fieldFunction = CreateNumberField, fieldName = "Channel", pageAddress = 0x07, valueWrite = function(value)
    return value - 1
  end, valueRead = function(value)
    return value + 1
  end, extraInfo = {min = 1, max = 24, prefix = "CH"}},
  { fieldFunction = CreateNumberField, fieldName = "Center", pageAddress = 0x08, valueRead = function(value)
    return value & 0xFFFF
  end, extraInfo = {min = -125, max = 125}},
  { fieldFunction = CreateNumberField, fieldName = "Holding strength", pageAddress = 0x11, getValue = function(value)
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
  { fieldFunction = CreateNumberField, fieldName = "Operation smoothing", pageAddress = 0x13, extraInfo = {min = 0, max = 50} },
  { fieldFunction = CreateNumberField, fieldName = "Deadband", pageAddress = 0x21, extraInfo = {min = 0, max = 90} },
}

local function create()
  series65build = false

  local sensor = sport.getSensor({appIdStart = 0x6800, appIdEnd = 0x680F})

  local line = form.addLine("")
  form.addTextButton(line, nil, "Save to flash", function()
    lastSaveTime = os.time()
    saveStep = 0
    writeDialog = form.openDialog({title = "Saving", message = "Writing save command ...", closeWhenClickOutside = false, buttons= {
      {label = "Cancel", action = function()
        if writeDialog ~= nil then
          writeDialog:close()
          writeDialog = nil
        end
      end}
    }, wakeup = function()
      if lastSaveTime + 1 > os.time() then
        if saveStep == 0 then
          if sensor:writeParameter(0x15, 7) then
            saveStep = 1
          end
        elseif saveStep == 1 then
          if sensor:writeParameter(0x30, 0) then
            if writeDialog ~= nil then
              writeDialog:message("Save successfully!")
            end
            saveStep = 2
          end
        end
        lastSaveTime = os.time()
      end
    end})
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

return {create = create, name = "XAct", wakeup = ConfigWakeup}
