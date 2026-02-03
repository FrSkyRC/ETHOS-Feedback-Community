-- Lua Bluetooth Test

local icon = lcd.loadMask("bluetooth.png")

local function create()
    -- Reset the orientation
    -- bluetooth.write(0xAFF2, 0x52)
    
    -- Reset the orientation too
    -- bluetooth.write(0xAFF2, 'R')

    -- Changes the device name
    bluetooth.write(0xFFD4, 'My HT')
    system.exit()
    return nil
end

local function init()
    system.registerSystemTool({name="Bluetooth Test", icon=icon, create=create})
end

return {init=init}
