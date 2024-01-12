-- Lua Form widget

local function create()
    return {color=lcd.RGB(100, 50, 50), text=""}
end

local function build(widget)
    form.create()
    local w, h = lcd.getWindowSize()
    form.addTextButton(nil, {x=20, y=20, w=math.max(170, w/2), h=40}, "Press here", function() print("Button pressed") end)
    form.addTextField(nil, {x=30, y=70, w=math.max(170, w/2), h=40}, function() return widget.text end, function(newValue) widget.text = newValue end)
    form.addColorField(nil, {x=40, y=120, w=math.max(170, w/2), h=40}, function() return widget.color end, function(newValue) widget.color = newValue end)
end    

local function paint(widget)
    local w, h = lcd.getWindowSize()
    lcd.color(widget.color)
    lcd.drawFilledRectangle(0, 0, w, h)
end

local function init()
    system.registerWidget({key="form", name="Form", create=create, build=build, paint=paint, title=false})
end

return {init=init}
