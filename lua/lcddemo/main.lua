-- Lua LCD demo widget

local bitmap, mask

local function paint(widget)
    -- Demo of a mask
    lcd.color(lcd.RGB(255, 255, 0))
    lcd.drawMask(0, 10, mask)

    -- Demo of a text
    lcd.font(FONT_ITALIC)
    lcd.color(lcd.RGB(255,0,255))
    lcd.drawText(15, 10, "FONT")

    -- Demo of a bitmap
    local w2, h2 = lcd.getWindowSize()
    lcd.drawBitmap(10, 25, bitmap, w2 - 20, h2 - 35)
end

local function init()
    bitmap = lcd.loadBitmap("FLASH:/bitmaps/system/default_glider.png")
    mask = lcd.loadMask("FLASH:/bitmaps/system/mask_dot.png")
    system.registerWidget({key="lcddemo", name="Lua LCD Demo", paint=paint})
end

return {init=init}
