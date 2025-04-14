-- Lua Tool example

local progress = nil
local progressValue = 0

local icon = lcd.loadMask("form.png")

local function fillPanel(data, panel)
    for i = 1, data.count do
        panel:addLine("Line " .. i) 
    end
end    

local function create()
    w, h = lcd.getWindowSize()

    local data = {
        text="", 
        color=lcd.RGB(100, 50, 50), 
        count=1,
        source=nil,
        sensor=nil,
        switch=nil,
        file=nil,
        bitmap=nil,
        number=5
    }

    form.addButton(nil, {x=w-170, y=0, w=160, h=160}, {
        text="Bitmap button", 
        icon=icon, 
        press=function() print("Button pressed") end
    })

    local line = form.addLine("TextDialog example")
    form.addButton(line, nil, {
        text="Press here", 
        press=function() 
            form.openDialog({
                width=w,
                title="Help",
                message="Increase D, P, I in order until each wobbles,\nthen back off.\nSet F for a good response in full\nstick flips and rolls.\nIf necessary, tweak P:D ratio\nto set response damping to your liking. Increase O until wobbles occur when jabbing elevator at full collective, back off a bit. Increase B if you want sharper response.\nIncrease D, P, I in order until each wobbles, then back off.\nSet F for a good response in full stick flips and rolls.\nIf necessary, tweak P:D ratio to set response damping to your liking.\nIncrease O until wobbles occur when jabbing elevator at full collective, back off a bit.\nIncrease B if you want sharper response.", 
                buttons={{label="OK", action=function() return true end}}, 
                wakeup=function()
                        lcd.invalidate()
                    end,  
                paint=function() 
                        local w, h = lcd.getWindowSize()
                        local left = w * 0.75 - 10
                        local top = 10
                        w = w / 4
                        h = h / 4
                        lcd.drawLine(left, top + h/2, left+w, top + h/2)
                        lcd.color(YELLOW)
                        for i = 0,w do
                            local val = math.sin(i*math.pi/(w/2))
                            lcd.drawPoint(left + i, top + val*h/2+h/2)
                        end

                    end,
                options=TEXT_LEFT
            })
        end})

    local line = form.addLine("ProgressDialog example")
    form.addTextButton(line, nil, "Press here", 
      function() 
        progress = form.openProgressDialog("Progress", "Doing some long job ...")
        -- progress:closeAllowed(false)
        progress:closeHandler(function() print("Progress dialog closed") end)
        progressValue = 0
      end)
    
    local line = form.addLine("Text example")
    form.addTextField(line, nil, function() return data.text end, function(newValue) data.text = newValue end)

    local line = form.addLine("Color example")
    local field = form.addColorField(line, nil, function() return data.color end, function(newValue) data.color = newValue end)
    field:focus()

    local panel = form.addExpansionPanel("Expansion panel")
    form.addButton(panel, {x=0, y=0, w=160, h=160}, {
        text="Button 1", 
        icon=icon, 
        press=function() print("Button 1 pressed") end
    })
    form.addButton(panel, {x=180, y=0, w=160, h=160}, {
        text="Button 2",
        icon=icon, 
        options=FONT_S,
        press=function() print("Button 2 pressed") end
    })

    local line = form.addLine("Expansion panel dynamic", false)
    local field = form.addNumberField(line, nil, 1, 5, function() return data.count end, function(value) 
        data.count = value
        panel:clear()
        fillPanel(data, panel)
    end)
    field:default(1)
    field:suffix(" lines")
    panel = form.addExpansionPanel("Lines")
    fillPanel(data, panel)
    panel:event(function(event) if event == EVT_OPEN then print("Expansion panel opened") elseif event == EVT_CLOSE then print("Expansion panel closed") end end)

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

    local line = form.addLine("Number example")
    local field = form.addNumberField(line, nil, -100, 100, function() return data.number end, function(newValue) data.number = newValue end)
    field:help("Cross Coupling:\nStart with a low gain. Increase in small increments\nuntil there is little to not noticeable cross coupling observed.")

    local line = form.addLine("Multi fields")
    local slots = form.getFieldSlots(line, {0, "-", 0})
    local field = form.addNumberField(line, slots[1], -100, 100, function() return data.number end, function(newValue) data.number = newValue end)
    field:help("Help1")
    form.addStaticText(line, slots[2], "-")
    local field = form.addNumberField(line, slots[3], -100, 100, function() return data.number end, function(newValue) data.number = newValue end)
    field:help("Acro Trainer gain. Acro trainer Mode is not self leveling but does limit the maximum pitch/roll angle. This determines how aggressively the helicopter tilts back to the maximum angle (if exceeded) while in Acro Trainer Mode")

    local line = form.addLine("Fields without line")
    for i=1, 3 do
        local y = form.height() + 10
        for x=10, w - 170, 180 do
            form.addNumberField(nil, {x=x, y=y, w=170, h=40}, -100, 100, function() return data.number end, function(newValue) data.number = newValue form.invalidate() end)
        end
    end

    return data
end    

local function wakeup(data)
    if progress then
        progressValue = progressValue + 1
        if progressValue > 100 then
            progress:close()
        else    
            progress:value(progressValue)
        end
    end    
end

local function event(data, category, value, x, y)
    print("Event received:", category, value, x, y)
    return false
end

local function init()
    system.registerSystemTool({name="Lua Form", icon=icon, create=create, wakeup=wakeup, event=event})
end

return {init=init}
