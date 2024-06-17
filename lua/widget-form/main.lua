-- Lua Form widget

local function create()
    return {color=lcd.RGB(100, 50, 50), text="", source=nil}
end

local function build(widget)
    local w, h = lcd.getWindowSize()

    local line = form.addLine("Source example")
    form.addSourceField(line, nil, function() return widget.source end, function(newValue) widget.source = newValue end)

    form.addTextButton(nil, {x=20, y=form.height() + 10, w=math.max(170, w/2), h=40}, "Clear Form!", function() print("Button pressed") form.clear() end)
    form.addTextField(nil, {x=20, y=form.height() + 10, w=math.max(170, w/2), h=40}, function() return widget.text end, function(newValue) widget.text = newValue end)
    form.addColorField(nil, {x=20, y=form.height() + 10, w=math.max(170, w/2), h=40}, function() return widget.color end, function(newValue) widget.color = newValue end)
end    

local function paint(widget)
    local w, h = lcd.getWindowSize()
    lcd.color(widget.color)
    lcd.drawFilledRectangle(0, 0, w, h)
end

local function init()
    system.registerWidget({key="luaform", name="Lua form in widget", create=create, build=build, paint=paint, title=false})
end

return {init=init}
