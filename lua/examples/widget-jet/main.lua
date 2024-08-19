-- Lua FrkJet

local pumpPanel, pumpPointer, rpmPanel, rpmPointer, egtPanel, egtPointer

local function create()
  if egtPanel == nil then
    pumpPanel = lcd.loadBitmap("pump_panel.png")
    pumpPointer = lcd.loadBitmap("pump_pointer.png")
    rpmPanel = lcd.loadBitmap("rpm_panel.png")
    rpmPointer = lcd.loadBitmap("rpm_pointer.png")
    egtPanel = lcd.loadBitmap("egt_panel.png")
    egtPointer = lcd.loadBitmap("egt_pointer.png")
  end
  return { angle=0 }
end

local function build(widget)
  local w, h = lcd.getWindowSize()
  if pumpPanel ~= nil then
    widget.pumpPanelLeft = w /2 - pumpPanel:width() / 2
    widget.pumpPanelTop = h / 2 - pumpPanel:height() / 2
  end
  if pumpPointer ~= nil then
    widget.pumpPointerLeft = w / 2 - pumpPointer:width() / 2
    widget.pumpPointerTop = h / 2 - pumpPointer:height() / 2
  end
  if rpmPanel ~= nil then
    widget.rpmPanelLeft = w / 4 - rpmPanel:width() / 2
    widget.rpmPanelTop = h / 2 - rpmPanel:height() / 2
  end
  if rpmPointer ~= nil then
    widget.rpmPointerLeft = w / 4 - rpmPointer:width() / 2
    widget.rpmPointerTop = h / 2 - rpmPointer:height() / 2
  end
  if egtPanel ~= nil then
    widget.egtPanelLeft = w * 3 / 4 - egtPanel:width() / 2
    widget.egtPanelTop = h / 2 - egtPanel:height() / 2
  end
  if egtPointer ~= nil then
    widget.egtPointerLeft = w * 3 / 4 - egtPointer:width() / 2
    widget.egtPointerTop = h / 2 - egtPointer:height() / 2
  end
end
  
local function paint(widget)
  if pumpPanel ~= nil then
    lcd.drawBitmap(widget.pumpPanelLeft, widget.pumpPanelTop, pumpPanel)
  end
  if pumpPointer ~= nil then
    lcd.drawBitmap(widget.pumpPointerLeft, widget.pumpPointerTop, pumpPointer:rotate(widget.angle))
  end
  if rpmPanel ~= nil then
    lcd.drawBitmap(widget.rpmPanelLeft, widget.rpmPanelTop, rpmPanel)
  end
  if rpmPointer ~= nil then
    lcd.drawBitmap(widget.rpmPointerLeft, widget.rpmPointerTop, rpmPointer:rotate(widget.angle))
  end  
  if egtPanel ~= nil then
    lcd.drawBitmap(widget.egtPanelLeft, widget.egtPanelTop, egtPanel)
  end
  if egtPointer ~= nil then
    lcd.drawBitmap(widget.egtPointerLeft, widget.egtPointerTop, egtPointer:rotate(widget.angle))
  end
end
  
local function wakeup(widget)
  widget.angle = (widget.angle + 1) % 360
  lcd.invalidate()
end

local function init()
  system.registerWidget({key="FrkJet", name="FrkJet", create=create, build=build, paint=paint, wakeup=wakeup})
end

return {init=init}
  