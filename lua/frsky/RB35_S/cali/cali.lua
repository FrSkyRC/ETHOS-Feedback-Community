-- RB35S Calibration Configure

local translations = {en="RB35S calibration"}

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
local nextOpTime

local SXR_CALI_HINTS = {
  "Place your RB35 horizontal, top side up.",
  "Place your RB35 horizontal, top side down.",
  "Place your RB35 vertical, battery pins down.",
  "Place your RB35 vertical, battery pins up.",
  "Place your RB35 front side facing you, label oriented.",
  "Place your RB35 front side facing you, label upside down.",
}

local idle = false
local function create()
  step = 0
  calibrationState = CALIBRATION_INIT
  idle = false

  local sensor = sport.getSensor({appIdStart=0x0F00, appIdEnd=0x0F0F});

  bitmap = lcd.loadBitmap("cali/cali_"..step..".png")

  return {sensor=sensor}
end

local function paint(widget)
  local width, height = lcd.getWindowSize()

  print("lcd:paint()")
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

local function wakeup(widget)
  -- TODO call discover
  if widget.sensor:appId() == 0xFFFF then
    local frame = widget.sensor:popFrame()
    if frame == nil then
      return
    end
    widget.sensor:module(frame:module())
    widget.sensor:band(frame:band())
    widget.sensor:rx(frame:rx())
    widget.sensor:appId(frame:appId())
  end
  if idle == false and widget.sensor:idle(true) == true then
    idle = true
  end
  if calibrationState == CALIBRATION_WRITE then
    print("CALIBRATION_WRITE")
    if widget.sensor:writeParameter(0xB2, step) == true then
      print("widget.sensor:writeParameter")
      calibrationState = CALIBRATION_READ
    end
  elseif calibrationState == CALIBRATION_READ then
    print("CALIBRATION_READ")
    if widget.sensor:requestParameter(0xB2) == true then
      print("widget.sensor:requestParameter")
      calibrationState = CALIBRATION_WAIT
      nextOpTime = os.clock() + 3
    end
  elseif calibrationState == CALIBRATION_WAIT then
    local value = widget.sensor:getParameter()
    if value then
      local fieldId = value % 256
      if fieldId == 0xB2 then
        if step == 5 then
          calibrationState = CALIBRATION_OK
          bitmap = lcd.loadBitmap("cali/cali_ok.png")
        else
          calibrationState = CALIBRATION_INIT
          step = (step + 1) % 6
          bitmap = lcd.loadBitmap("cali/cali_"..step..".png")
        end
        lcd.invalidate()
      end
    elseif os.clock() >= nextOpTime then
      calibrationState = CALIBRATION_WRITE
    end
  end
end

local function event(widget, category, value, x, y)
  print("event", category, value, x, y)
  if category == EVT_KEY and value == KEY_ENTER_BREAK then
    if calibrationState == CALIBRATION_INIT then
      calibrationState = CALIBRATION_WRITE
      lcd.invalidate()
      return true
    end
  end
  return false
end

local function close(widget)
  print("close()")
  widget.sensor:idle(false)
  idle = false
end

return {name=name, create=create, paint=paint, wakeup=wakeup, event=event, close=close}
