-- @author flyingeek
-- more widgets on my github page https://github.com/flyingeek
--
local function init()
    system.registerTheme({
        key = "NightOp",
        name = "Night Ops",
        roundButtons = true,
        focusStyle = "outline",
        borderWidth = 3,
        colors = {
            lcd.RGB(0xD0, 0x01, 0x00), -- PRIMARY_COLOR (#D00100 instrument red)
            lcd.RGB(0x6B, 0x10, 0x00), -- SECONDARY_BGCOLOR (dark warm red panels — lum ~0.033)
            lcd.RGB(0xD8, 0x18, 0x00), -- HIGHLIGHT_COLOR (#D81800)
            COLOR_BLACK,               -- HIGHLIGHT_CONTRASTING_COLOR
            lcd.RGB(0xC8, 0x60, 0x60), -- DISABLE_COLOR (muted coral — 4.1:1 on PRIMARY, 3.2:1 on SECONDARY)
            lcd.RGB(0x18, 0x00, 0x00), -- PRIMARY_BGCOLOR (#180000)
            COLOR_BLACK,               -- OVERLAY_COLOR
            lcd.RGB(0x80, 0x00, 0x00), -- SECONDARY_COLOR (#800000 dark maroon)
            lcd.RGB(0x44, 0xAA, 0x44), -- SAFE_COLOR (#44AA44 muted cockpit green)
            COLOR_BLACK,               -- PAGE_BGCOLOR
            lcd.RGB(0xFF, 0x55, 0x00), -- ERROR_COLOR (#FF5500 orange-red)
            lcd.RGB(0xFF, 0x44, 0x00), -- ACTIVE_COLOR (= HIGHLIGHT_COLOR)
            lcd.RGB(0x5A, 0x18, 0x00), -- INACTIVE_COLOR (dim dark ember)
            lcd.RGB(0xFF, 0x44, 0x00), -- BUTTON_BORDER_ACTIVE_COLOR
            lcd.RGB(0x40, 0x0A, 0x00), -- BUTTON_BORDER_COLOR
            lcd.RGB(0xFF, 0xAA, 0x00), -- WARNING_COLOR (cockpit amber — hue ~40°, 7.7:1 on PRIMARY)
            COLOR_BLACK,               -- SAFE_CONTRASTING_COLOR (9.9:1 on cockpit green)
            COLOR_BLACK,               -- TOPLCD_BGCOLOR (XE/S)
        },
        toolbarLogo = "none",
        toolbarBackground = lcd.loadBitmap("toolbar-nightops.png"),
    })
end
return {
    init = init
}
