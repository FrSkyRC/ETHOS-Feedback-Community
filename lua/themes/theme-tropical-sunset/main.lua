-- @author flyingeek
-- more widgets on my github page https://github.com/flyingeek
--
local function init()
    system.registerTheme({
        key = "TSunset",
        name = "Tropical Sunset",
        roundButtons = true,
        focusStyle = "invert",
        colors = {
            lcd.RGB(0xFF, 0xE8, 0xA0), -- PRIMARY_COLOR (warm yellow-cream — #FFE8A0)
            lcd.RGB(0x3A, 0x00, 0x60), -- SECONDARY_BGCOLOR (deep violet panels — darker than PRIMARY_BGCOLOR, lum ~0.017)
            lcd.RGB(0xFF, 0x45, 0x00), -- HIGHLIGHT_COLOR (orange-red — #FF4500, 6.1:1 on PRIMARY_BGCOLOR)
            COLOR_BLACK,               -- HIGHLIGHT_CONTRASTING_COLOR (dark purple on orange)
            lcd.RGB(0xCC, 0x78, 0xA0), -- DISABLE_COLOR (dusty rose — 3.8:1 on PRIMARY, 5.1:1 on SECONDARY)
            lcd.RGB(0x5D, 0x00, 0x5C), -- PRIMARY_BGCOLOR (deep magenta-purple canvas — lum ~0.031)
            COLOR_BLACK,               -- OVERLAY_COLOR
            lcd.RGB(0xFF, 0xD7, 0x00), -- SECONDARY_COLOR (golden yellow — #FFD700)
            lcd.RGB(0x00, 0xFF, 0x88), -- SAFE_COLOR (tropical mint — success signal)
            lcd.RGB(0x26, 0x00, 0x45), -- PAGE_BGCOLOR (darkest purple — lum ~0.007)
            lcd.RGB(0xFF, 0x22, 0x44), -- ERROR_COLOR (crimson — #FF2244, hue ~348° distinct from orange HIGHLIGHT)
            lcd.RGB(0xFF, 0x77, 0x00), -- ACTIVE_COLOR (= HIGHLIGHT_COLOR)
            lcd.RGB(0x80, 0x40, 0x90), -- INACTIVE_COLOR (muted violet)
            lcd.RGB(0xFF, 0x77, 0x00), -- BUTTON_BORDER_ACTIVE_COLOR
            lcd.RGB(0x79, 0x4C, 0x98), -- BUTTON_BORDER_COLOR
            lcd.RGB(0xFF, 0xC2, 0x00), -- WARNING_COLOR (golden amber — hue ~46° distinct from orange HIGHLIGHT, 7.2:1 on PRIMARY)
            lcd.RGB(0x1A, 0x00, 0x28), -- SAFE_CONTRASTING_COLOR
            COLOR_BLACK,               -- TOPLCD_BGCOLOR (XE/S)
        },
        --toolbarLogo = "none",
        toolbarBackground = lcd.loadBitmap("toolbar-tsunset.png"),
    })
end
return {
    init = init
}
