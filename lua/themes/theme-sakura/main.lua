-- @author flyingeek
-- more widgets on my github page https://github.com/flyingeek
--
local function init()
    system.registerTheme({
        key = "Sakura",
        name = "Sakura",
        roundButtons = true,
        focusStyle = "invert",
        colors = {
            lcd.RGB(0x2A, 0x08, 0x20), -- PRIMARY_COLOR          #2A0820 dark charcoal-rose
            lcd.RGB(0xFF, 0xE8, 0xF2), -- SECONDARY_BGCOLOR      #FFE8F2 very pale blush panels
            lcd.RGB(0xA4, 0x00, 0x55), -- HIGHLIGHT_COLOR        #A40055 deep cherry
            lcd.RGB(0xFF, 0xE8, 0xF0), -- HIGHLIGHT_CONTRASTING_COLOR #FFE8F0 pale blush on deep cherry
            lcd.RGB(0xB0, 0x60, 0x90), -- DISABLE_COLOR          #B06090 muted rose
            lcd.RGB(0xFF, 0xCC, 0xE5), -- PRIMARY_BGCOLOR        #FFCCE5 pale rose home canvas
            lcd.RGB(0x83, 0x77, 0x7B), -- OVERLAY_COLOR          #83777B warm grey overlay
            lcd.RGB(0x6B, 0x10, 0x40), -- SECONDARY_COLOR        #6B1040 dark cherry captions/icons
            lcd.RGB(0x4B, 0x72, 0x4B), -- SAFE_COLOR             #4B724B sage green
            lcd.RGB(0xFF, 0xB9, 0xDC), -- PAGE_BGCOLOR           #FFB9DC cherry pink
            lcd.RGB(0xFF, 0x00, 0x04), -- ERROR_COLOR            #FF0004 bright red
            lcd.RGB(0x4B, 0x72, 0x4B), -- ACTIVE_COLOR           #4B724B sage green (= SAFE)
            lcd.RGB(0x6B, 0x10, 0x40), -- INACTIVE_COLOR         #6B1040 dark cherry (= SECONDARY)
            lcd.RGB(0xB5, 0x00, 0x5E), -- BUTTON_BORDER_ACTIVE_COLOR #B5005E deep cherry (= HIGHLIGHT)
            lcd.RGB(0xD8, 0x84, 0xB1), -- BUTTON_BORDER_COLOR    #D884B1 medium rose
            lcd.RGB(0x8C, 0x74, 0x00), -- WARNING_COLOR          #8C7400 golden yellow
            lcd.RGB(0xFF, 0xE8, 0xF0), -- SAFE_CONTRASTING_COLOR #FFE8F0 pale blush on green
            COLOR_WHITE,               -- TOPLCD_BGCOLOR (XE/S)
        },
        toolbarLogo = "none",
        toolbarBackground = lcd.loadBitmap("toolbar-sakura.png"),
    })
end
return {
    init = init
}
