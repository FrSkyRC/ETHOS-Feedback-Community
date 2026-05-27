-- @author flyingeek
-- more widgets on my github page https://github.com/flyingeek
--
local function init()
    system.registerTheme({
        key = "Moebius",
        name = "Dracula Moebius Red",
        roundButtons = true,
        focusStyle = "invert",
        colors = {
            lcd.RGB(0xF8, 0xF8, 0xF2), -- PRIMARY_COLOR
            lcd.RGB(0x42, 0x44, 0x50), -- SECONDARY_BGCOLOR
            lcd.RGB(255, 170, 153),    -- HIGHLIGHT_COLOR (189, 147, 249)(#BD93F9) or (255, 170, 153)(#FFAA99)
            lcd.RGB(0x19, 0x1A, 0x21), -- HIGHLIGHT_CONTRASTING_COLOR
            lcd.RGB(0xA9, 0x70, 0x79), -- DISABLE_COLOR
            lcd.RGB(0x2C, 0x21, 0x22), -- PRIMARY_BGCOLOR
            COLOR_BLACK,               -- OVERLAY_COLOR
            lcd.RGB(0xb8, 0xc3, 0xe4), -- SECONDARY_COLOR
            lcd.RGB(0x69, 0xFF, 0x94), -- SAFE_COLOR
            lcd.RGB(0x5E, 0x13, 0x17), -- PAGE_BGCOLOR
            lcd.RGB(0xDE, 0x57, 0x35), -- ERROR_COLOR
            lcd.RGB(0x69, 0xFF, 0x94), -- ACTIVE_COLOR
            lcd.RGB(0xb8, 0xc3, 0xe4), -- INACTIVE_COLOR 0xFF, 0x80, 0xBF
            lcd.RGB(0x81, 0x5C, 0xD6), -- BUTTON_BORDER_ACTIVE_COLOR
            lcd.RGB(0x50, 0x52, 0x61), -- BUTTON_BORDER_COLOR
            lcd.RGB(0xA3, 0x95, 0x14), -- WARNING_COLOR
            lcd.RGB(0x19, 0x1A, 0x21), -- SAFE_CONTRASTING_COLOR
            COLOR_BLACK,               -- TOPLCD_BGCOLOR (XE/S)
        },
        --toolbarLogo = "none",
        toolbarBackground = lcd.loadBitmap("toolbar-moebius-plain.png")
        -- alternatively, if you want the dracula mascot, use this line instead:
        --toolbarBackground = lcd.loadBitmap("toolbar-moebius-logo.png"),
    })
end
return {
    init = init
}
