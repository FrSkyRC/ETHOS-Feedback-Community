-- Lua Kill Test

local function create()
    return nil
end

local leak = {}
local function wakeup()
    for i=1, 1000 do
        leak[#leak + 1] = "leak"
    end
end    

local icon = lcd.loadMask("kill.png")

local function init()
    system.registerSystemTool({name="Kill Test", icon=icon, create=create, wakeup=wakeup})
end

return {init=init}
