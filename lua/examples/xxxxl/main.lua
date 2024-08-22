-- XXXXL widget

local function create()
    local font = lcd.loadFont("xxxxl.fnt")
    return {font=font, color=lcd.RGB(255, 0, 0)}
end

local function paint(widget)
    local w, h = lcd.getWindowSize()
    lcd.color(widget.color)
    lcd.font(widget.font)
    lcd.drawText(w / 2, 50, "Land   NOW!", CENTERED)
end

local function init()
    system.registerWidget({key="xxxxl", name="xxxxl", create=create, paint=paint})
end

return {init=init}
