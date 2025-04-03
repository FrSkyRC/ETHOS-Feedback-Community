-- Lua LCD demo widget

local bitmap, mask

local function paint(widget)
    local w, h = lcd.getWindowSize()

    -- Demo of a mask
    lcd.color(lcd.RGB(255, 255, 0))
    lcd.drawMask(0, 10, mask)

    -- Demo of a text
    lcd.font(FONT_ITALIC)
    lcd.color(lcd.RGB(255,0,255))
    lcd.drawText(15, 10, "FONT")

    -- Demo of a bitmap with clipping
    lcd.setClipping(w - 120, h - 120, 100, 100)
    lcd.drawBitmap(w - 120, h - 120, bitmap)

    -- Demo of a bitmap
    lcd.setClipping()
    lcd.drawBitmap(10, 25, bitmap)

    -- Demo of a filled triangle
    local x = 50
    local y = 225
    lcd.color(WHITE)
    lcd.drawFilledTriangle(x, y+6, x+5, y, x+5, y+10)
end

local function init()
    bitmap = lcd.loadBitmap("FLASH:/bitmaps/system/Archer+SR12+.png")
    mask = lcd.loadMask("FLASH:/bitmaps/system/mask_dot.png")
    system.registerWidget({key="lcddemo", name="Lua LCD Demo", paint=paint})
end

return {init=init}
