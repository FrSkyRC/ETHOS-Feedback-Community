assert(loadfile("config.lua"))()

local progressDialog = nil
local xactType = 1
local xActSettingsAddress = {0x11, 0x12, 0x13, 0x15, 0x21}
local BLS65_settings = {4, 10, 1, 7, 1}
local M525_settings = {6, 5, 1, 7, 1}
local W565_settings = {5, 5, 1, 7, 1}
local S5451H_settings = {6, 4, 8, 7, 1}
local S5452H_settings = {6, 6, 6, 7, 1}
local S5453H_settings = {4, 6, 3, 7, 1}
local S5454H_settings = {4, 6, 4, 7, 1}
local S5455H_settings = {5, 6, 6, 7, 1}
local LD5801_settings = {7, 5, 1, 7, 1}

local xActSettingsTable = {
  BLS65_settings,
  BLS65_settings,
  BLS65_settings,
  M525_settings,
  W565_settings,
  S5451H_settings,
  S5452H_settings,
  S5453H_settings,
  S5454H_settings,
  S5455H_settings,
  LD5801_settings,
  LD5801_settings,
  LD5801_settings,
}

local xActSettingsValuePairs = {
  {"BLS65 Series",  1},
  {"BLS54 Series",  2},
  {"MD5301H",       3},
  {"M525 Series",   4},
  {"M565 Series",   5},
  {"S5451H",        6},
  {"S5452H",        7},
  {"S5453H",        8},
  {"S5454H",        9},
  {"S5455H",        10},
  {"LD5801(A)",     11},
  {"D5701(A)",      12},
  {"H5701",         13}
}

local parameters = {
  { fieldFunction = CreatePhyIdField, fieldName = "Physical Id", pageAddress = 0x00, defaultValue = 10, extraInfo = {} },
  { fieldFunction = CreateAppIdField, fieldName = "Application Id", pageAddress = 0x01, extraInfo = {} },
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
}

local series65Parameters = {
  { fieldFunction = CreateChoiceField, fieldName = "Working mode", pageAddress = 0x40, extraInfo = {valuePairs = {{"Angle mode", 0}, {"Range mode", 1}, {"Rotate mode", 2}}, } },
  { fieldFunction = CreateNumberField, fieldName = "XAct max angle", pageAddress = 0x41, extraInfo = {min = 0, max = 359, suffix = " Degree"} },
}

local series65build = false
local writeDialog = nil
local lastSaveTime = 0

local function create()
  series65build = false
  xactType = 1

  local sensor = sport.getSensor({appIdStart = 0x6800, appIdEnd = 0x680F})

  local line = form.addLine("")
  form.addTextButton(line, nil, "Save to flash", function()
    lastSaveTime = os.time()
    writeDialog = form.openDialog({title = "Saving", message = "Writing save command ...", closeWhenClickOutside = false, buttons= {
      {label = "Cancel", action = function()
        if writeDialog ~= nil then
          writeDialog:close()
          writeDialog = nil
        end
      end}
    }, wakeup = function()
      if lastSaveTime + 1 > os.time() then
        if sensor:writeParameter(0x30, 0) then
          if writeDialog ~= nil then
            writeDialog:message("Save successfully!")
          end
        end
        lastSaveTime = os.time()
      end
    end})
    return 0
  end)

  Params = parameters
  ReceiveValueHandler = function ()
    if progressDialog ~= nil then
      local finished = 0
      for _, parameter in ipairs(Params) do
        for _, addr in ipairs(xActSettingsAddress) do
          if parameter.pageAddress == addr then
            if parameter.state == FieldState.RECEIVED then
              finished = finished + 1
            end
          end
        end
      end
      local per = finished * 100 / 5
      progressDialog:value(per)
      if per == 100 then
        progressDialog:closeAllowed(true)
        progressDialog:message("Write successfully!")
      end
    end

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

  -- Parameters line
  local line = form.addLine("XAct series")
  form.addChoiceField(line, nil, xActSettingsValuePairs, function()
    return xactType
  end, function(value)
    xactType = value
    for index, addr in ipairs(xActSettingsAddress) do
      for _, param in ipairs(Params) do
        if param.pageAddress == addr then
          param.value = xActSettingsTable[xactType][index]
          param.state = FieldState.DIRTY
          break
        end
      end
    end
    progressDialog = form.openProgressDialog({title = "Writing", message = "Writing parameters ...", close = function ()
      progressDialog = nil
    end})
    progressDialog:closeAllowed(false)
  end)

  for _, addr in ipairs(xActSettingsAddress) do
    local p = { pageAddress = addr, state = FieldState.INIT }
    Params[#Params + 1] = p
  end

  return {sensor = sensor, needIdle = false}
end

local function close(data)
  local addresses = {0x11, 0x12, 0x13, 0x15, 0x21, 0x40, 0x41}
  for _, addr in ipairs(addresses) do
    for index, param in ipairs(Params) do
      if param ~= nil and param.pageAddress ~= nil and param.pageAddress == addr then
        for i = index, #Params do
          Params[i] = Params[i + 1]
        end
        Params[#Params] = nil
      end
    end
  end
  ConfigClose(data)
end

return {create = create, name = "XAct", wakeup = ConfigWakeup, close = close}
