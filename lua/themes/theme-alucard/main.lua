-- @author flyingeek
-- more widgets on my github page https://github.com/flyingeek
--
local function init()
    system.registerTheme({
        key = "Alucard",
        name = "Alucard",
        roundButtons = true,
        focusStyle = "invert",
        colors = {
            lcd.RGB(0x1F, 0x1F, 0x1F), -- PRIMARY_COLOR
            lcd.RGB(0xCE, 0xCC, 0xC0), -- SECONDARY_BGCOLOR
            lcd.RGB(100, 74, 201),     -- HIGHLIGHT_COLOR (#644AC9)
            lcd.RGB(0xFF, 0xFF, 0xF5), -- HIGHLIGHT_CONTRASTING_COLOR
            lcd.RGB(0x87, 0x7F, 0x5E), -- DISABLE_COLOR
            lcd.RGB(0xFF, 0xFF, 0xF5), -- PRIMARY_BGCOLOR
            lcd.GREY(0x60),            -- OVERLAY_COLOR
            lcd.RGB(0x3E, 0x3A, 0x2B), -- SECONDARY_COLOR
            lcd.RGB(0x08, 0x91, 0x08), -- SAFE_COLOR
            lcd.RGB(0xEA, 0xEA, 0xE0), -- PAGE_BGCOLOR
            lcd.RGB(0xCB, 0x3A, 0x2A), -- ERROR_COLOR
            lcd.RGB(0x08, 0x91, 0x08), -- ACTIVE_COLOR
            lcd.RGB(0x3E, 0x3A, 0x2B), -- INACTIVE_COLOR
            lcd.RGB(0x81, 0x5C, 0xD6), -- BUTTON_BORDER_ACTIVE_COLOR xCF
            lcd.RGB(0xBC, 0xBA, 0xB3), -- BUTTON_BORDER_COLOR
            lcd.RGB(0xA3, 0x95, 0x14), -- WARNING_COLOR
            lcd.RGB(0xFF, 0xFF, 0xF5), -- SAFE_CONTRASTING_COLOR
            COLOR_WHITE,               -- TOPLCD_BGCOLOR (XE/S)
        },
        --toolbarLogo = "none",
        toolbarBackground = lcd.loadBitmap("toolbar-alucard-plain.png"),
        -- alternatively, if you want the dracula mascot, use this line instead:
        --toolbarBackground = lcd.loadBitmap("toolbar-alucard-logo.png"),
    })
end
return {
    init = init
}
