-- Lua Gauge widget

local translations = {en="Lua Gauge", fr="Jauge Lua"}

local function name(widget)
    local locale = system.getLocale()
    return translations[locale] or translations["en"]
end

local function create()
    return {color=lcd.RGB(0xEA, 0x5E, 0x00), source=nil, min=-1024, max=1024, value=0}
end

local function paint(widget)
    local w, h = lcd.getWindowSize()

    if widget.source == nil then
        return
    end

    -- Define positions
    if h < 50 then
        lcd.font(FONT_XS)
    elseif h < 80 then
        lcd.font(FONT_S)
    elseif h > 170 then
        lcd.font(FONT_XL)
    else
        lcd.font(FONT_STD)
    end

    local text_w, text_h = lcd.getTextSize("")
    local box_top, box_height = text_h, h - text_h - 4
    local box_left, box_width = 4, w - 8

    -- Source name and value
    lcd.drawText(box_left, 0, widget.source:name())
    lcd.drawText(box_left + box_width, 0, widget.source:stringValue(), RIGHT)

    -- Compute percentage
    local percent = (widget.value - widget.min) / (widget.max - widget.min) * 100
    if percent > 100 then
        percent = 100
    elseif percent < 0 then
        percent = 0
    end

    -- Gauge background
    gauge_width = math.floor((((box_width - 2) / 100) * percent) + 2)
    lcd.color(lcd.RGB(200, 200, 200))
    lcd.drawFilledRectangle(box_left, box_top, box_width, box_height)

    -- Gauge color
    lcd.color(widget.color)

    -- Gauge bar
    lcd.drawFilledRectangle(box_left, box_top, gauge_width, box_height)

    -- Gauge frame outline
    lcd.color(BLACK)
    lcd.drawRectangle(box_left, box_top, box_width, box_height)

    -- Gauge percentage
    lcd.drawText(box_left + box_width / 2, box_top + (box_height - text_h) / 2, math.floor(percent).."%", CENTERED)
end

local function wakeup(widget)
    if widget.source then
        local newValue = widget.source:value()
        if widget.value ~= newValue then
            widget.value = newValue
            lcd.invalidate()
        end
    end
end

local function configure(widget)
    -- Source choice
    line = form.addLine("Source")
    form.addSourceField(line, nil, function() return widget.source end, function(value) widget.source = value end)

    -- Color
    line = form.addLine("Color")
    form.addColorField(line, nil, function() return widget.color end, function(color) widget.color = color end)

    -- Min & Max
    line = form.addLine("Range")
    local slots = form.getFieldSlots(line, {0, "-", 0})
    form.addNumberField(line, slots[1], -1024, 1024, function() return widget.min end, function(value) widget.min = value end)
    form.addStaticText(line, slots[2], "-")
    form.addNumberField(line, slots[3], -1024, 1024, function() return widget.max end, function(value) widget.max = value end)
end

local function read(widget)
    widget.source = storage.read("source")
    widget.min = storage.read("min")
    widget.max = storage.read("max")
    widget.color = storage.read("color")
end

local function write(widget)
    storage.write("source", widget.source)
    storage.write("min", widget.min)
    storage.write("max", widget.max)
    storage.write("color", widget.color)
end

local function init()
    system.registerWidget({key="gauge", name=name, create=create, paint=paint, wakeup=wakeup, configure=configure, read=read, write=write})
end

return {init=init}
