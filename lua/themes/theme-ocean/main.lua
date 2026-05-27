-- @author flyingeek
-- more widgets on my github page https://github.com/flyingeek
--
local function init()
    system.registerTheme({
        key = "Ocean",
        name = "Ocean",
        roundButtons = true,
        focusStyle = "invert",
        colors = {
            lcd.RGB(0xD8, 0xE8, 0xFF), -- PRIMARY_COLOR (blanc glacé)
            lcd.RGB(0x2C, 0x44, 0x68), -- SECONDARY_BGCOLOR (acier bleu panel — lum ~3.4x PRIMARY)
            lcd.RGB(0x44, 0x88, 0xFF), -- HIGHLIGHT_COLOR (bleu royal vif)
            COLOR_BLACK,               -- HIGHLIGHT_CONTRASTING_COLOR (6.3:1 on royal blue)
            lcd.RGB(0x58, 0x75, 0xA1), -- DISABLE_COLOR (bleu ardoise éteint)
            lcd.RGB(0x18, 0x20, 0x40), -- PRIMARY_BGCOLOR (bleu nuit — lum ~0.016 = Dracula)
            COLOR_BLACK,               -- OVERLAY_COLOR
            lcd.RGB(0x88, 0xBB, 0xDD), -- SECONDARY_COLOR (bleu ciel lisible)
            lcd.RGB(0x84, 0xC3, 0x0F), -- SAFE_COLOR (vert ethos)
            lcd.RGB(0x0E, 0x18, 0x30), -- PAGE_BGCOLOR (plus sombre que PRIMARY)
            lcd.RGB(0xFF, 0x44, 0x44), -- ERROR_COLOR (rouge vif)
            lcd.RGB(0x44, 0x88, 0xFF), -- ACTIVE_COLOR (bleu royal)
            lcd.RGB(0x2A, 0x50, 0x80), -- INACTIVE_COLOR (bleu terne)
            lcd.RGB(0x44, 0x88, 0xFF), -- BUTTON_BORDER_ACTIVE_COLOR
            lcd.RGB(0x39, 0x59, 0x88), -- BUTTON_BORDER_COLOR
            lcd.RGB(0xFF, 0x8C, 0x00), -- WARNING_COLOR (warning orange — 6.9:1 on PRIMARY, 4.3:1 on SECONDARY)
            COLOR_BLACK,               -- SAFE_CONTRASTING_COLOR
            COLOR_BLACK,               -- TOPLCD_BGCOLOR (XE/S)
        },
        --toolbarLogo = "none",
        toolbarBackground = lcd.loadBitmap("toolbar-ocean.png")
    })
end
return {
    init = init
}
