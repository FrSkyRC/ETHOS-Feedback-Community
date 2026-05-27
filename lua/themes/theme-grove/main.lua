-- @author flyingeek
-- more widgets on my github page https://github.com/flyingeek
--
local function init()
    system.registerTheme({
        key = "Grove",
        name = "Grove",
        roundButtons = true,
        focusStyle = "invert",
        colors = {
            lcd.RGB(0xE8, 0xF5, 0xEE), -- PRIMARY_COLOR (near-white green)
            lcd.RGB(0x1C, 0x40, 0x28), -- SECONDARY_BGCOLOR (forest panels — lum ~3.4× PRIMARY_BGCOLOR)
            lcd.RGB(0xA8, 0xE6, 0x3A), -- HIGHLIGHT_COLOR (vivid spring green)
            lcd.RGB(0x06, 0x1A, 0x0E), -- HIGHLIGHT_CONTRASTING_COLOR (dark on vivid green)
            lcd.RGB(0x54, 0x7A, 0x64), -- DISABLE_COLOR (muted sage — 2.2:1 on PAGE, 3.6:1 on canvas)
            lcd.RGB(0x0F, 0x22, 0x1A), -- PRIMARY_BGCOLOR (deep forest canvas — lum ~0.011)
            COLOR_BLACK,               -- OVERLAY_COLOR
            lcd.RGB(0x8C, 0xC4, 0xA0), -- SECONDARY_COLOR (medium sage)
            lcd.RGB(0x50, 0xFA, 0x7B), -- SAFE_COLOR (lime green)
            lcd.RGB(0x0E, 0x4A, 0x3D), -- PAGE_BGCOLOR (#0E4A3D — rich forest green)
            lcd.RGB(0xFF, 0x22, 0x44), -- ERROR_COLOR (crimson — #FF2244, 4.5:1 on forest green)
            lcd.RGB(0x22, 0xD6, 0x6A), -- ACTIVE_COLOR (vivid spring green)
            lcd.RGB(0x70, 0x9C, 0x7A), -- INACTIVE_COLOR (muted sage — 3.3:1 on PAGE)
            lcd.RGB(0x22, 0xD6, 0x6A), -- BUTTON_BORDER_ACTIVE_COLOR
            lcd.RGB(0x21, 0x5B, 0x39), -- BUTTON_BORDER_COLOR
            lcd.RGB(0xF4, 0xA0, 0x35), -- WARNING_COLOR (amber — caution, was ERROR_COLOR)
            lcd.RGB(0x06, 0x1A, 0x0E), -- SAFE_CONTRASTING_COLOR
            COLOR_BLACK,               -- TOPLCD_BGCOLOR (XE/S)
        },
        --toolbarLogo = "none",
        toolbarBackground = lcd.loadBitmap("toolbar-grove.png"),
    })
end
return {
    init = init
}
