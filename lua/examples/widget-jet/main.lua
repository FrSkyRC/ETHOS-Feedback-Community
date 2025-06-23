-- Lua FrkJet
---@diagnostic disable: undefined-global

-- Bitmap resources
local pumpPanel, pumpPointer, rpmPanel, rpmPointer, egtPanel, egtPointer, speedPanel, speedPointer

-- Values
local altValue = 0
local altUnit = ""

local fuelValue = 0

local rpmValue = 0
local rpmUnit = ""

local pumpValue = 0

local egtValue = 0
local egtUnit = ""

local speedValue = 0
local speedUnit = ""

local function calRotaryAngle(percent)
  local angle = 315 + percent * 270 / 100
  while angle > 360 do
    angle = angle - 360
  end
  return angle
end

local function calRotaryAngleWithLimit(min, percent, max)
  return calRotaryAngle((percent - min) * 100 / (max - min))
end

local function limit(min, value, max)
  return math.max(math.min(value, max), min)
end

local function create()
  if egtPanel == nil then
    pumpPanel = lcd.loadBitmap("pump_panel.png")
    pumpPointer = lcd.loadBitmap("pump_pointer.png")
    rpmPanel = lcd.loadBitmap("rpm_panel.png")
    rpmPointer = lcd.loadBitmap("rpm_pointer.png")
    egtPanel = lcd.loadBitmap("egt_panel.png")
    egtPointer = lcd.loadBitmap("egt_pointer.png")
    speedPanel = lcd.loadBitmap("speed_panel.png")
    speedPointer = lcd.loadBitmap("speed_pointer.png")
  end
  return { maxFuel = 100, maxRpm = 100, maxEgt = 100, maxSpeed = 100}
end

local function build(widget)
  local w, h = lcd.getWindowSize()
  if rpmPanel ~= nil then
    widget.rpmPanelLeft = w / 4 - rpmPanel:width() / 2
    widget.rpmPanelTop = h / 2 - rpmPanel:height() / 2
  end
  if rpmPointer ~= nil then
    widget.rpmPointerLeft = w / 4 - rpmPointer:width() / 2
    widget.rpmPointerTop = h / 2 - rpmPointer:height() / 2
  end

  if speedPanel ~= nil then
    widget.speedPanelLeft = w * 3 / 4 - speedPanel:width() / 2
    widget.speedPanelTop = h / 2 - speedPanel:height() / 2
  end
  if speedPointer ~= nil then
    widget.speedPointerLeft = w * 3 / 4 - speedPointer:width() / 2
    widget.speedPointerTop = h / 2 - speedPointer:height() / 2
  end

  if egtPanel ~= nil then
    widget.egtPanelLeft = w / 2 - egtPanel:width() / 2
    widget.egtPanelTop = h / 4 - egtPanel:height() / 2
  end
  if egtPointer ~= nil then
    widget.egtPointerLeft = w / 2 - egtPointer:width() / 2
    widget.egtPointerTop = h / 4 - egtPointer:height() / 2
  end

  if pumpPanel ~= nil then
    widget.pumpPanelLeft = w / 2 - pumpPanel:width() / 2
    widget.pumpPanelTop = h * 3 / 4 - pumpPanel:height() / 2
  end
  if pumpPointer ~= nil then
    widget.pumpPointerLeft = w / 2 - pumpPointer:width() / 2
    widget.pumpPointerTop = h * 3 / 4 - pumpPointer:height() / 2
  end

  widget.altArea = {x = 10, y = h / 2, h = h}
  widget.fuelArea = {x = w - 20, w = 20, h = h}
end

local PIXEL_PER_CURSOR = 20
local VALUE_PER_CURSOR = 2
local VALUE_PER_BIG_CURSOR = 10

local function paintAltitude(widget)
  lcd.font(FONT_S)
  local textW, textH = lcd.getTextSize(altValue)

  local ceilValue = math.ceil(altValue)
  local adj = ceilValue % VALUE_PER_CURSOR
  if adj ~= 0 then
    ceilValue = ceilValue + (VALUE_PER_CURSOR - adj)
  end
  local ceilY = widget.altArea.y - PIXEL_PER_CURSOR * (ceilValue - altValue) / VALUE_PER_CURSOR
  while ceilY > 0 do
    ceilY = ceilY - PIXEL_PER_CURSOR
    ceilValue = ceilValue + VALUE_PER_CURSOR
  end

  lcd.color(lcd.GREY(0xFF))
  while ceilY < widget.altArea.y * 2 do
    local isBigCursor = ceilValue % VALUE_PER_BIG_CURSOR == 0
    lcd.drawLine(0, ceilY, isBigCursor and widget.altArea.x or widget.altArea.x / 2, ceilY)
    if isBigCursor then
      lcd.drawText(widget.altArea.x + 5, ceilY - textH / 2, ceilValue)
    end
    ceilY = ceilY + PIXEL_PER_CURSOR
    ceilValue = ceilValue - VALUE_PER_CURSOR
  end

  lcd.color(lcd.GREY(0x00))
  local x = 0
  while x <= PIXEL_PER_CURSOR / 2 do
    lcd.drawLine(widget.altArea.x + x, widget.altArea.y - x, widget.altArea.x + x, widget.altArea.y + x)
    x = x + 1
  end
  lcd.drawFilledRectangle(widget.altArea.x + PIXEL_PER_CURSOR / 2, widget.altArea.y - PIXEL_PER_CURSOR / 2, textW + 10, PIXEL_PER_CURSOR)

  lcd.color(lcd.GREY(0xFF))
  lcd.drawLine(widget.altArea.x, widget.altArea.y, widget.altArea.x + PIXEL_PER_CURSOR / 2, widget.altArea.y - PIXEL_PER_CURSOR / 2)
  lcd.drawLine(widget.altArea.x + PIXEL_PER_CURSOR / 2, widget.altArea.y - PIXEL_PER_CURSOR / 2, widget.altArea.x + PIXEL_PER_CURSOR / 2 + textW + 10, widget.altArea.y - PIXEL_PER_CURSOR / 2)
  lcd.drawLine(widget.altArea.x, widget.altArea.y, widget.altArea.x + PIXEL_PER_CURSOR / 2, widget.altArea.y + PIXEL_PER_CURSOR / 2)
  lcd.drawLine(widget.altArea.x + PIXEL_PER_CURSOR / 2, widget.altArea.y + PIXEL_PER_CURSOR / 2, widget.altArea.x + PIXEL_PER_CURSOR / 2 + textW + 10, widget.altArea.y + PIXEL_PER_CURSOR / 2)
  lcd.drawLine(widget.altArea.x + PIXEL_PER_CURSOR / 2 + textW + 10, widget.altArea.y - PIXEL_PER_CURSOR / 2, widget.altArea.x + PIXEL_PER_CURSOR / 2 + textW + 10, widget.altArea.y + PIXEL_PER_CURSOR / 2)
  lcd.drawText(widget.altArea.x + PIXEL_PER_CURSOR / 2 + 5, widget.altArea.y - textH / 2, altValue)

  local maxW = lcd.getTextSize("-9999")
  lcd.drawText(widget.altArea.x + 5 + maxW, widget.altArea.h - textH * 2, altUnit)
  lcd.drawText(widget.altArea.x + 5 + maxW, widget.altArea.h - textH, "Altitude")
end

local function paintFuel(widget)
  lcd.color(lcd.GREY(0xFF))
  lcd.drawLine(widget.fuelArea.x, 0, widget.fuelArea.x + widget.fuelArea.w, 0)
  lcd.drawLine(widget.fuelArea.x, widget.fuelArea.h / 4, widget.fuelArea.x + widget.fuelArea.w, widget.fuelArea.h / 4)
  lcd.drawLine(widget.fuelArea.x, widget.fuelArea.h / 2, widget.fuelArea.x + widget.fuelArea.w, widget.fuelArea.h / 2)
  lcd.drawLine(widget.fuelArea.x, widget.fuelArea.h * 3 / 4, widget.fuelArea.x + widget.fuelArea.w, widget.fuelArea.h * 3 / 4)
  lcd.drawLine(widget.fuelArea.x, widget.fuelArea.h - 1, widget.fuelArea.x + widget.fuelArea.w, widget.fuelArea.h - 1)
  lcd.drawFilledRectangle(widget.fuelArea.x + widget.fuelArea.w - 3, 0, widget.fuelArea.x + widget.fuelArea.w, widget.fuelArea.h)

  local textW, textH = lcd.getTextSize("E")
  lcd.drawText(widget.fuelArea.x - textW, 0, "F", RIGHT)
  lcd.drawText(widget.fuelArea.x - textW, (widget.fuelArea.h - textH) / 2, "1/2", RIGHT)
  lcd.drawText(widget.fuelArea.x - textW, widget.fuelArea.h - textH, "E", RIGHT)

  local y = widget.fuelArea.h * (widget.maxFuel - fuelValue) / widget.maxFuel
  lcd.drawFilledRectangle(widget.fuelArea.x + widget.fuelArea.w / 2, y, widget.fuelArea.w / 2, widget.fuelArea.h - y)
end

local function paint(widget)
  local textW, textH = lcd.getTextSize(rpmValue)

  -- RPM
  if rpmPanel ~= nil and rpmPointer ~= nil then
    lcd.drawBitmap(widget.rpmPanelLeft, widget.rpmPanelTop, rpmPanel)
    lcd.color(lcd.GREY(0xFF))
    lcd.drawText(widget.rpmPanelLeft + rpmPanel:width() / 2, widget.rpmPanelTop + rpmPanel:height() / 2 + textH, rpmValue, CENTERED)
    lcd.drawText(widget.rpmPanelLeft + rpmPanel:width() / 2, widget.rpmPanelTop + rpmPanel:height() / 2 + textH * 2, rpmUnit, CENTERED)
    local angle = calRotaryAngleWithLimit(0, rpmValue, widget.maxRpm)
    lcd.drawBitmap(widget.rpmPointerLeft, widget.rpmPointerTop, rpmPointer:rotate(angle))
  end

  -- Speed
  if speedPanel ~= nil and speedPointer ~= nil then
    lcd.drawBitmap(widget.speedPanelLeft, widget.speedPanelTop, speedPanel)
    lcd.color(lcd.GREY(0xFF))
    lcd.drawText(widget.speedPanelLeft + speedPanel:width() / 2, widget.speedPanelTop + speedPanel:height() / 2 + textH, speedValue, CENTERED)
    lcd.drawText(widget.speedPanelLeft + speedPanel:width() / 2, widget.speedPanelTop + speedPanel:height() / 2 + textH * 2, speedUnit, CENTERED)
    local angle = calRotaryAngleWithLimit(0, speedValue, widget.maxSpeed)
    lcd.drawBitmap(widget.speedPointerLeft, widget.speedPointerTop, speedPointer:rotate(angle))
  end

  -- Egt
  if egtPanel ~= nil and egtPointer ~= nil then
    lcd.drawBitmap(widget.egtPanelLeft, widget.egtPanelTop, egtPanel)
    lcd.color(lcd.GREY(0xFF))
    lcd.drawText(widget.egtPanelLeft + egtPanel:width() / 2, widget.egtPanelTop + egtPanel:height() / 2 + textH, math.floor(egtValue) .. egtUnit, CENTERED)
    local angle = calRotaryAngleWithLimit(0, egtValue, widget.maxEgt)
    lcd.drawBitmap(widget.egtPointerLeft, widget.egtPointerTop, egtPointer:rotate(angle))
  end

  -- Pump
  if pumpPanel ~= nil and pumpPointer ~= nil then
    lcd.drawBitmap(widget.pumpPanelLeft, widget.pumpPanelTop, pumpPanel)
    lcd.color(lcd.GREY(0xFF))
    lcd.drawText(widget.pumpPanelLeft + pumpPanel:width() / 2, widget.pumpPanelTop + pumpPanel:height() / 2 + textH, math.floor(pumpValue) .. "%", CENTERED)
    local angle = calRotaryAngleWithLimit(0, pumpValue, 100)
    lcd.drawBitmap(widget.pumpPointerLeft, widget.pumpPointerTop, pumpPointer:rotate(angle))
  end

  -- Altitude
  paintAltitude(widget)

  -- Fuel
  paintFuel(widget)
end

local function wakeup(widget)
  local invalidateNeeded = false
  if widget.altSource ~= nil then
    local newValue = widget.altSource:value()
    if altValue ~= newValue then
      altValue = newValue
      invalidateNeeded = true
    end
    local newUnit = widget.altSource:stringUnit() or ""
    if altUnit ~= newUnit then
      altUnit = newUnit
      invalidateNeeded = true
    end
  end

  if widget.rpmSource ~= nil and widget.maxRpm ~= nil then
    local newValue = widget.rpmSource:value()
    newValue = limit(0, newValue, widget.maxRpm)
    if rpmValue ~= newValue then
      rpmValue = newValue
      invalidateNeeded = true
    end
    local newUnit = widget.rpmSource:stringUnit() or ""
    if rpmUnit ~= newUnit then
      rpmUnit = newUnit
      invalidateNeeded = true
    end
  end

  if widget.speedSource ~= nil and widget.maxSpeed ~= nil then
    local newValue = widget.speedSource:value()
    newValue = limit(0, newValue, widget.maxSpeed)
    if speedValue ~= newValue then
      speedValue = newValue
      invalidateNeeded = true
    end
    local newUnit = widget.speedSource:stringUnit() or ""
    if speedUnit ~= newUnit then
      speedUnit = newUnit
      invalidateNeeded = true
    end
  end

  if widget.fuelSource ~= nil and widget.maxFuel ~= nil then
    local newValue = widget.fuelSource:value()
    newValue = limit(0, newValue, widget.maxFuel)
    if fuelValue ~= newValue then
      fuelValue = newValue
      invalidateNeeded = true
    end
  end

  if widget.pumpSource ~= nil then
    local newValue = widget.pumpSource:value()
    newValue = limit(0, newValue, 100)
    if pumpValue ~= newValue then
      pumpValue = newValue
      invalidateNeeded = true
    end
  end

  if widget.egtSource ~= nil and widget.maxEgt ~= nil then
    local newValue = widget.egtSource:value()
    newValue = limit(0, newValue, widget.maxEgt)
    if egtValue ~= newValue then
      egtValue = newValue
      invalidateNeeded = true
    end
    local newUnit = widget.egtSource:stringUnit() or ""
    if egtUnit ~= newUnit then
      egtUnit = newUnit
      invalidateNeeded = true
    end
  end

  if invalidateNeeded then
    lcd.invalidate()
  end
end

local function configure(widget)
  local line = form.addLine("Altitude source")
  form.addSourceField(line, nil, function() return widget.altSource end, function(newValue) widget.altSource = newValue end)

  local panel = form.addExpansionPanel("RPM configure")
  local rpmMaxEdit
  line = panel:addLine("RPM source")
  form.addSourceField(line, nil, function() return widget.rpmSource end, function(newValue)
    widget.rpmSource = newValue
    if rpmMaxEdit ~= nil and widget.rpmSource ~= nil then
      rpmMaxEdit:suffix(widget.rpmSource:stringUnit())
    end
  end)
  line = panel:addLine("Max RPM")
  rpmMaxEdit = form.addNumberField(line, nil, 0, 10000, function() return widget.maxRpm end, function(newValue) widget.maxRpm = newValue end)
  if widget.rpmSource ~= nil then
    rpmMaxEdit:suffix(widget.rpmSource:stringUnit())
  end

  panel = form.addExpansionPanel("Speed configure")
  local speedMaxEdit
  line = panel:addLine("Speed source")
  form.addSourceField(line, nil, function() return widget.speedSource end, function(newValue)
    widget.speedSource = newValue
    if speedMaxEdit ~= nil and widget.speedSource ~= nil then
      speedMaxEdit:suffix(widget.speedSource:stringUnit())
    end
  end)
  line = panel:addLine("Max Speed")
  speedMaxEdit = form.addNumberField(line, nil, 0, 10000, function() return widget.maxSpeed end, function(newValue) widget.maxSpeed = newValue end)
  if widget.speedSource ~= nil then
    speedMaxEdit:suffix(widget.speedSource:stringUnit())
  end

  panel = form.addExpansionPanel("Fuel configure")
  local maxFuelEdit
  line = panel:addLine("Fuel source")
  form.addSourceField(line, nil, function() return widget.fuelSource end, function(newValue)
    widget.fuelSource = newValue
    if maxFuelEdit ~= nil and widget.fuelSource ~= nil then
      maxFuelEdit:suffix(widget.fuelSource:stringUnit())
    end
  end)
  line = panel:addLine("Max fuel")
  maxFuelEdit = form.addNumberField(line, nil, 0, 10000, function() return widget.maxFuel end, function(newValue) widget.maxFuel = newValue end)
  if widget.fuelSource ~= nil then
    maxFuelEdit:suffix(widget.fuelSource:stringUnit())
  end

  panel = form.addExpansionPanel("EGT configure")
  local egtMaxEdit
  line = panel:addLine("EGT source")
  form.addSourceField(line, nil, function() return widget.egtSource end, function(newValue)
    widget.egtSource = newValue
    if egtMaxEdit ~= nil and widget.egtSource ~= nil then
      egtMaxEdit:suffix(widget.egtSource:stringUnit())
    end
  end)
  line = panel:addLine("Max EGT")
  egtMaxEdit = form.addNumberField(line, nil, 0, 10000, function() return widget.maxEgt end, function(newValue) widget.maxEgt = newValue end)
  if widget.egtSource ~= nil then
    maxFuelEdit:suffix(widget.egtSource:stringUnit())
  end

  line = form.addLine("Pump source")
  form.addSourceField(line, nil, function() return widget.pumpSource end, function(newValue) widget.pumpSource = newValue end)
end

local function read(widget)
  widget.altSource = storage.read("altSource")

  widget.rpmSource = storage.read("rpmSource")
  widget.maxRpm = storage.read("maxRpm")

  widget.speedSource = storage.read("speedSource")
  widget.maxSpeed = storage.read("maxSpeed")

  widget.fuelSource = storage.read("fuelSource")
  widget.maxFuel = storage.read("maxFuel")

  widget.egtSource = storage.read("egtSource")
  widget.maxEgt = storage.read("maxEgt")

  widget.pumpSource = storage.read("pumpSource")
end

local function write(widget)
  storage.write("altSource", widget.altSource)

  storage.write("rpmSource", widget.rpmSource)
  storage.write("maxRpm", widget.maxRpm)

  storage.write("speedSource", widget.speedSource)
  storage.write("maxSpeed", widget.maxSpeed)

  storage.write("fuelSource", widget.fuelSource)
  storage.write("maxFuel", widget.maxFuel)

  storage.write("egtSource", widget.egtSource)
  storage.write("maxEgt", widget.maxEgt)

  storage.write("pumpSource", widget.pumpSource)
end

local function init()
  system.registerWidget({ key = "FrkJet", name = "Jet dashboard", create = create, build = build, paint = paint, wakeup = wakeup, configure = configure, read = read, write = write, title = false })
end

return { init = init }
