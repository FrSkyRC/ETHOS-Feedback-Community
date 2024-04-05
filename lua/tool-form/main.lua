-- Lua Tool example

local function fillPanel(data, panel)
    for i = 1, data.count do
        panel:addLine("Line " .. i) 
    end
end    

local function create()
    local data = {
        text="", 
        color=lcd.RGB(100, 50, 50), 
        count=1,
        source=nil,
        sensor=nil,
        switch=nil,
        file=nil,
        bitmap=nil,
    }

    local line = form.addLine("Button example")
    form.addTextButton(line, nil, "Press here", function() print("Button pressed") end)
    
    local line = form.addLine("Text example")
    form.addTextField(line, nil, function() return data.text end, function(newValue) data.text = newValue end)

    local line = form.addLine("Color example")
    form.addColorField(line, nil, function() return data.color end, function(newValue) data.color = newValue end)

    local line = form.addLine("Expansion panel example")
    local panel
    local field = form.addNumberField(line, nil, 1, 5, function() return data.count end, function(value) 
        data.count = value
        panel:clear()
        fillPanel(data, panel)
    end)
    field:default(1)
    field:suffix(" lines")
    panel = form.addExpansionPanel("Lines")
    fillPanel(data, panel)

    local line = form.addLine("Source example")
    form.addSourceField(line, nil, function() return data.source end, function(newValue) data.source = newValue end)

    local line = form.addLine("Switch example")
    local field = form.addSwitchField(line, nil, function() return data.switch end, function(newValue) data.switch = newValue end)
    field:enable(false)

    local line = form.addLine("Sensor example (mAh)")
    form.addSensorField(line, nil, function() return data.sensor end, function(newValue) data.sensor = newValue end, function(candidate) return candidate:unit() == UNIT_MILLIAMPERE_HOUR end)

    local line = form.addLine("File example")
    form.addFileField(line, nil, "/audio/en", "audio", function() return data.file end, function(newValue) data.file = newValue end)

    local line = form.addLine("Bitmap example")
    form.addBitmapField(line, nil, "/bitmaps/models", function() return data.bitmap end, function(newValue) data.bitmap = newValue end)

    return data
end    

local function wakeup(data)
end

local function event(data, category, value, x, y)
    print("Event received:", category, value, x, y, KEY_EXIT_BREAK)
    return false
end

local icon = lcd.loadMask("servo.png")

local function init()
    system.registerSystemTool({name="Form", icon=icon, create=create, wakeup=wakeup, event=event})
end

return {init=init}
