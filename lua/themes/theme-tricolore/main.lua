-- @author flyingeek
-- more widgets on my github page https://github.com/flyingeek
--
local function init()
    system.registerTheme({
        key = "Tricol",
        name = "Tricolore",
        roundButtons = true,
        focusStyle = "invert",
        colors = {
            lcd.RGB(0xE0, 0xE8, 0xFF), -- PRIMARY_COLOR (cool near-white)
            lcd.RGB(0x26, 0x3A, 0x84), -- SECONDARY_BGCOLOR (rich navy panels — lum ~3.4× PRIMARY_BGCOLOR)
            lcd.RGB(0xED, 0x29, 0x39), -- HIGHLIGHT_COLOR (French red — #ED2939)
            lcd.RGB(0xF0, 0xF4, 0xFF), -- HIGHLIGHT_CONTRASTING_COLOR (near-white on red)
            lcd.RGB(0x52, 0x6C, 0xB4), -- DISABLE_COLOR (muted dark blue)
            lcd.RGB(0x14, 0x1E, 0x58), -- PRIMARY_BGCOLOR (deep navy — lum ~0.015)
            COLOR_BLACK,               -- OVERLAY_COLOR
            lcd.RGB(0x88, 0x99, 0xDD), -- SECONDARY_COLOR (slate blue)
            lcd.RGB(0x66, 0xBB, 0xFF), -- SAFE_COLOR (sky blue)
            lcd.RGB(0x0E, 0x16, 0x3C), -- PAGE_BGCOLOR (deepest navy — lum ~0.008)
            lcd.RGB(0xFF, 0x17, 0x44), -- ERROR_COLOR (neon red — #FF1744, 4.2:1 on navy, distinct from flag red HIGHLIGHT)
            lcd.RGB(0xED, 0x29, 0x39), -- ACTIVE_COLOR (French red)
            lcd.RGB(0x3A, 0x4E, 0x8A), -- INACTIVE_COLOR (muted navy)
            lcd.RGB(0xED, 0x29, 0x39), -- BUTTON_BORDER_ACTIVE_COLOR (French red)
            lcd.RGB(0x30, 0x4A, 0xA8), -- BUTTON_BORDER_COLOR
            lcd.RGB(0xFF, 0x6B, 0x2B), -- WARNING_COLOR (orange — caution, was ERROR_COLOR)
            COLOR_BLACK,               -- SAFE_CONTRASTING_COLOR (10.2:1 on sky blue)
            COLOR_BLACK,               -- TOPLCD_BGCOLOR (XE/S)
        },
        --toolbarLogo = "none",
        toolbarBackground = lcd.loadBitmap("toolbar-tricolore.png"),
    })
end
return {
    init = init
}
