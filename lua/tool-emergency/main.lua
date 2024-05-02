-- Lua Emergency Test

local function create()
    system.emergency()
    return nil
end    

local icon = lcd.loadMask("em.png")

local function init()
    system.registerSystemTool({name="Emergency Test", icon=icon, create=create})
end

return {init=init}
