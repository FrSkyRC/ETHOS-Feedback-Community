-- Lua FLVSS widget

local function create()
  local sensor = system.getSource("LiPo")
  return {sensor=sensor}
end

local function paint(widget)
  local w, h = lcd.getWindowSize()
    local text_w, text_h = lcd.getTextSize("")
    if widget.sensor ~= nil then
      lcd.font(FONT_XL)
      lcd.drawText(10, 10, "Total = "..widget.sensor:stringValue(), LEFT)
      lcd.drawText(w - 10, 10, widget.sensor:stringValue(OPTION_CELL_COUNT).." Cells", RIGHT)

      local cellsCount = widget.sensor:value(OPTION_CELL_COUNT)

      local x = 10
      local y = 50

      for i = 1, cellsCount do
        if x + 180 > w then
          x = 10;
          y = y + 40;
        end

        lcd.drawText(x, y, "Cell"..i.."  "..widget.sensor:stringValue(OPTION_CELL_INDEX(i)), LEFT)
        x = x + 180
      end
  end  
end

local function wakeup(widget)
  if widget.sensor ~= nil then
    lcd.invalidate()
  else 
    widget.sensor = system.getSource("LiPo1")
  end
end

local function init()
  system.registerWidget({key="flvss", name="Lua Flvss", create=create, paint=paint, wakeup=wakeup})
end

return {init=init}
