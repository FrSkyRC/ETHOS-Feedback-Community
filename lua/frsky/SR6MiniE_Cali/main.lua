-- SRX Calibration

local translations = {en="SR6Mini(E) Cali"}

local function name(widget)
  local locale = system.getLocale()
  return translations[locale] or translations["en"]
end

local CALIBRATION_INIT = 0
local CALIBRATION_WRITE = 1
local CALIBRATION_READ = 2
local CALIBRATION_WAIT = 3
local CALIBRATION_OK = 4

local step = 0
local bitmap
local calibrationState = CALIBRATION_INIT
local external = false
local open = false

local CALI_LABELS = {
  "Place your SRX horizontal, top side up.",
  "Place your SRX horizontal, top side down.",
  "Place your SRX vertical, antenna down.",
  "Place your SRX vertical, antenna up.",
  "Place your SRX CH3/4/5 connector side down.",
  "Place your SRX CH3/4/5 connector side up.",
}

local function create()
  step = 0
  calibrationState = CALIBRATION_INIT

  local sensor = sport.getSensor(0x0c30);

  local moduleLine = form.addLine("Module")
  local module = form.addChoiceField(moduleLine, nil, {{"Internal", 0x00}, {"External", 0x01}},
    function() return external end,
    function(value)
      external = value
    end)
  moduleLine = form.addLine("")
  form.addTextButton(moduleLine, nil, "CALIBRATE",
    function()
      open = true
      module:enable(false)
      if calibrationState == CALIBRATION_INIT then
        calibrationState = CALIBRATION_WRITE
      end
    end)

  bitmap = lcd.loadBitmap("/scripts/SR6MiniE_Cali/cali_"..step..".png")

  return {sensor=sensor}
end

local function paint(widget)
  local width, height = lcd.getWindowSize()

  if calibrationState == CALIBRATION_OK then
    lcd.drawText(width / 2, height / 2, "Calibration finished", CENTERED)
  else
    lcd.drawText(width / 2, height / 3, CALI_LABELS[step + 1], CENTERED)
    if calibrationState == CALIBRATION_INIT then
      lcd.drawText(width / 2, height / 3 + 25, "Press CALIBRATE to start", CENTERED)
    else
      lcd.drawText(width / 2, height / 3 + 25, "Waiting...", CENTERED)
    end
  end
  local w = bitmap:width()
  local h = bitmap:height()
  local x = width / 2 - w / 2
  local y = height / 3 * 2 - h / 2
  lcd.drawBitmap(x, y, bitmap)
end

local function wakeup(widget)
    if external then
      widget.sensor:module(0x01)
    end
    if calibrationState == CALIBRATION_WRITE then
      print("CALIBRATION_WRITE")
      if widget.sensor:writeParameter(0x60, step) == true then
        calibrationState = CALIBRATION_READ
        lcd.invalidate()
      end
    elseif calibrationState == CALIBRATION_READ then
      print("CALIBRATION_READ")
      if widget.sensor:requestParameter(0x60) == true then
        calibrationState = CALIBRATION_WAIT
      end
    elseif calibrationState == CALIBRATION_WAIT then
      local value = widget.sensor:getParameter()
      if value then
        local fieldId = value % 256
        if fieldId == 0x60 then
          if step == 5 then
            calibrationState = CALIBRATION_OK
            bitmap = lcd.loadBitmap("/scripts/SR6MiniE_Cali/cali_ok.png")
          else
            calibrationState = CALIBRATION_INIT
            step = (step + 1) % 6
            bitmap = lcd.loadBitmap("/scripts/SR6MiniE_Cali/cali_"..step..".png")
          end
          lcd.invalidate()
        end
      end
    end
--  end
end

local icon = lcd.loadMask("srx.png")

local function init()
  system.registerSystemTool({name=name, icon=icon, create=create, paint=paint, wakeup=wakeup})
end

return {init=init}
