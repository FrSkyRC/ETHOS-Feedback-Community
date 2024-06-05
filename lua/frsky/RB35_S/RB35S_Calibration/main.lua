-- RB35S Calibration Configure

local translations = {en="RB35S Calibration"}

local function name(widget)
  local locale = system.getLocale()
  return translations[locale] or translations["en"]
end

local CALIBRATION_INIT = 0
local CALIBRATION_WRITE = 1
local CALIBRATION_READ = 2
local CALIBRATION_WAIT = 3
local CALIBRATION_OK = 4

local requestInProgress = false
local step = 0
local modifications = {}
local repeatTimes = 0
local bitmap
local calibrationState = CALIBRATION_INIT

local SXR_CALI_HINTS = {
  "Place your RB35 horizontal, top side up.",
  "Place your RB35 horizontal, top side down.",
  "Place your RB35 vertical, pins up.",
  "Place your RB35 vertical, pins down.",
  "Place your RB35 legible lettering, pins right.",
  "Place your RB35 not legible lettering, pins left.",
}

local function create()
  requestInProgress = false
  refreshIndex = 0
  modifications = {}
  repeatTimes = 0
  fields = {}
  stabIndex = 1
  step = 0
  calibrationState = CALIBRATION_INIT 

  local sensor = sport.getSensor({appIdStart=0xF00, appIdEnd=0xF0F});

  bitmap = lcd.loadBitmap("/scripts/RB35S_Calibration/cali_"..step..".png")

  return {sensor=sensor}
end

local function paint(widget)
  local width, height = lcd.getWindowSize()

  lcd.drawText(width / 2, 10, "Calibration of SxR Gyros and Accelerometers", CENTERED)

  if calibrationState == CALIBRATION_OK then
    lcd.drawText(width / 2, height / 2, "Calibration finished", CENTERED)
  else
    lcd.drawText(width / 2, height / 3 - 20, SXR_CALI_HINTS[step + 1], CENTERED)
    if calibrationState == CALIBRATION_INIT then
      lcd.drawText(width / 2, height / 3, "Press ENTER to start", CENTERED)
    else
      lcd.drawText(width / 2, height / 3, "Waiting...", CENTERED)
    end
  end
  local w = bitmap:width()
  local h = bitmap:height()
  local x = width / 2 - w / 2
  local y = height / 3 * 2 - h / 2
  lcd.drawBitmap(x, y, bitmap)
end

local idle = false
local function wakeup(widget)
  if widget.sensor:alive() then
    if idle == false then
      widget.sensor:idle()
      idle = true
    end
    if calibrationState == CALIBRATION_WRITE then
      print("CALIBRATION_WRITE")
      if widget.sensor:writeParameter(0x60, step) == true then
        calibrationState = CALIBRATION_READ
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
            bitmap = lcd.loadBitmap("/scripts/RB35S_Calibration/cali_ok.png")
          else
            calibrationState = CALIBRATION_INIT
            step = (step + 1) % 6
            bitmap = lcd.loadBitmap("/scripts/RB35S_Calibration/cali_"..step..".png")
          end
          lcd.invalidate()
        end
      end
    end
  end
end

local function event(widget, category, value, x, y)
  print("event", category, value, x, y)
  print("KEY_ENTER_BREAK", KEY_ENTER_BREAK)
  if category == EVT_KEY and value == KEY_EXIT_BREAK then
    widget.sensor:idle(false)
  elseif category == EVT_KEY and value == 97 then
    if calibrationState == CALIBRATION_INIT then
      calibrationState = CALIBRATION_WRITE
      print("event lcd.invalidate()")
      lcd.invalidate()
    end
  end
  return false
end

local icon = lcd.loadMask("rb35.png")

local function close(widget)
  widget.sensor:idle(false)
end

local function init()
  system.registerSystemTool({name=name, icon=icon, create=create, paint=paint, wakeup=wakeup, event=event, close=close})
end

return {init=init}
