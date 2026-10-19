-- Lua Wizard example

local armSwtch
local armBitmap = lcd.loadMask("arm.png")

local function wizardInit()
    print("Wizard init")
    armSwtch = system.getSource({category=CATEGORY_SWITCH_POSITION, member=0})
end

local function pageAvailable()
    print("Wizard page available ?")
    return true
end

local function pageBuild()
    print("Wizard page build")
    local w, h = lcd.getWindowSize()
    local line = form.addLine("Arm Switch", nil, false)
    form.addSwitchField(line, nil, function() return armSwtch end, function(newValue) armSwtch = newValue end)
end

local function pageWakeup()
    -- print("Wizard page wakeup")
end

local function pagePaint()
    print("Wizard page paint")
    local w, h = lcd.getWindowSize()
    lcd.color(COLOR_ORANGE)
    lcd.drawLine(0, 0, w, h)
    lcd.drawLine(0, h, w, 0)
    lcd.drawMask(100, 100, armBitmap)
end

local function pageEvent(category, value, x, y)
    print("Wizard page event", category, value, x, y)
    return false
end

local function wizardRun()
    print("Wizard run")
    if armSwtch:category() ~= CATEGORY_NONE then
        print("Wizard will add an Arm mix ...")
        -- model.createMix("free", {name="Arm", actions={{condition=armSwtch, action="offset", active=100, inactive=0}}})
        model.createMix("free", {name="Arm", condition=armSwtch, input={category=CATEGORY_SPECIAL, member=0}})
    end
end

local function init()
    system.registerWizardPage({init=wizardInit, available=pageAvailable, build=pageBuild, wakeup=pageWakeup, paint=pagePaint, event=pageEvent, run=wizardRun})
end

return {init=init}
