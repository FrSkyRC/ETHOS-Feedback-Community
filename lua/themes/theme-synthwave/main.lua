-- @author flyingeek
-- more widgets on my github page https://github.com/flyingeek
--
local function init()
    system.registerTheme({
        key = "Synth",
        name = "Synthwave",
        roundButtons = true,
        focusStyle = "invert",
        colors = {
            lcd.RGB(0xE8, 0xF0, 0xFF), -- 1  PRIMARY_COLOR              (near-white ice-blue — lum 0.877)
            lcd.RGB(0x1E, 0x1B, 0x5E), -- 2  SECONDARY_BGCOLOR          (indigo panels — lum 0.016, 5.3× ratio)
            lcd.RGB(0xFF, 0x2D, 0x78), -- 3  HIGHLIGHT_COLOR            (neon hot pink — lum 0.236)
            lcd.RGB(0x06, 0x05, 0x1A), -- 4  HIGHLIGHT_CONTRASTING_COLOR (near-black on pink — 5.6:1)
            lcd.RGB(0x55, 0x58, 0xA0), -- 5  DISABLE_COLOR              (muted indigo-blue — lum 0.113)
            lcd.RGB(0x0D, 0x0B, 0x2A), -- 6  PRIMARY_BGCOLOR            (deep indigo — lum 0.003)
            COLOR_BLACK,               -- 7  OVERLAY_COLOR
            lcd.RGB(0x00, 0xDD, 0xFF), -- 8  SECONDARY_COLOR            (electric cyan — clock, nav icons)
            lcd.RGB(0x00, 0xFF, 0x9F), -- 9  SAFE_COLOR                 (neon mint green)
            lcd.RGB(0x06, 0x05, 0x1A), -- 10 PAGE_BGCOLOR               (near-black indigo — lum 0.001)
            lcd.RGB(0xFF, 0x3B, 0x5C), -- 11 ERROR_COLOR                (vivid red-pink)
            lcd.RGB(0x00, 0xFF, 0x9F), -- 12 ACTIVE_COLOR               (neon mint, same as SAFE)
            lcd.RGB(0x90, 0x90, 0xC8), -- 13 INACTIVE_COLOR             (muted lavender)
            lcd.RGB(0x00, 0xAA, 0xCC), -- 14 BUTTON_BORDER_ACTIVE_COLOR (dimmed cyan)
            lcd.RGB(0x15, 0x13, 0x42), -- 15 BUTTON_BORDER_COLOR
            lcd.RGB(0xFF, 0x8C, 0x1A), -- 16 WARNING_COLOR              (neon orange)
            lcd.RGB(0x06, 0x05, 0x1A), -- 17 SAFE_CONTRASTING_COLOR     (near-black on mint)
            COLOR_BLACK,               -- 18 TOPLCD_BGCOLOR (XE/S)
        },
        toolbarLogo = "none",
        toolbarBackground = lcd.loadBitmap("toolbar-synthwave.png"),
    })
end
return {
    init = init
}
