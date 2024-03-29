-- Lua RSSI widget

local function create()
    return {value=nil}
end

local function paint(widget)
    local w, h = lcd.getWindowSize()
    local text_w, text_h = lcd.getTextSize("")
    if widget.value ~= nil then
        lcd.font(FONT_XL)
        lcd.drawText(w/2, (h - text_h)/2, "RSSI = "..widget.value, CENTERED)
    end
end

local function wakeup(widget)
    local sensor = system.getSource("RSSI")
    local newValue = nil
    if sensor ~= nil then
        newValue = sensor:stringValue()
    end
    if widget.value ~= newValue then
        widget.value = newValue
        lcd.invalidate()
    end
end

local function menu(widget)
    return {
        {"Lua... playNumber(RSSI)",
         function()
             local sensor = system.getSource("RSSI")
             system.playNumber(sensor:value(), sensor:unit(), sensor:decimals())
         end},
    }
end

local function event(widget, category, value, x, y)
    print("Event received:", category, value, x, y)
    if category == EVT_KEY and value == KEY_ENTER_LONG then
        print("Board " .. system.getVersion().board .. " Version " .. system.getVersion().version)
        print("Date " .. os.date() .. " Time " .. os.time())
        lcd.invalidate()
        system.killEvent(value)
        return true
    else
        return false
    end
end

local function init()
    system.registerWidget({key="RSSI", name="Lua RSSI", create=create, paint=paint, event=event, menu=menu, wakeup=wakeup})
end

return {init=init}
