-- @author flyingeek
-- more widgets on my github page https://github.com/flyingeek
--
local function init()
    system.registerTheme({
        key = "Matrix",
        name = "Matrix",
        roundButtons = true,
        focusStyle = "invert",
        colors = {
            lcd.RGB(0x00, 0xD2, 0x38), -- 1  PRIMARY_COLOR (matrix green text)
            lcd.RGB(0x00, 0x33, 0x00), -- 2  SECONDARY_BGCOLOR (dark forest panel — ~8× ratio vs PRIMARY_BGCOLOR)
            lcd.RGB(0x00, 0xFF, 0x41), -- 3  HIGHLIGHT_COLOR (bright matrix rain green)
            COLOR_BLACK,               -- 4  HIGHLIGHT_CONTRASTING_COLOR (black on bright green)
            lcd.RGB(0x1A, 0x8C, 0x32), -- 5  DISABLE_COLOR (muted mid-green — ~4.6:1 on canvas, ~3.3:1 on panel)
            lcd.RGB(0x00, 0x10, 0x00), -- 6  PRIMARY_BGCOLOR (near-black green canvas)
            COLOR_BLACK,               -- 7  OVERLAY_COLOR
            lcd.RGB(0x00, 0x94, 0x23), -- 8  SECONDARY_COLOR (dark-mid green for labels, clock, nav icons)
            lcd.RGB(0xAA, 0xFF, 0x00), -- 9  SAFE_COLOR (chartreuse-lime — hue ~73° vs HIGHLIGHT ~136°, clearly distinct)
            COLOR_BLACK,               -- 10 PAGE_BGCOLOR (pure black for all forms and lists)
            lcd.RGB(0xFF, 0x33, 0x00), -- 11 ERROR_COLOR (vivid red-orange — unmistakable against all-green palette)
            lcd.RGB(0x00, 0xFF, 0x41), -- 12 ACTIVE_COLOR (bright matrix green)
            lcd.RGB(0x00, 0x6B, 0x1A), -- 13 INACTIVE_COLOR (dim dark green — intentionally ghosted)
            lcd.RGB(0x00, 0xFF, 0x41), -- 14 BUTTON_BORDER_ACTIVE_COLOR
            lcd.RGB(0x00, 0x48, 0x00), -- 15 BUTTON_BORDER_COLOR
            lcd.RGB(0xFF, 0xAA, 0x00), -- 16 WARNING_COLOR (amber)
            COLOR_BLACK,               -- 17 SAFE_CONTRASTING_COLOR (black on chartreuse)
            COLOR_BLACK,               -- 18 TOPLCD_BGCOLOR (XE/S)
        },
        toolbarLogo = "none",
        toolbarBackground = lcd.loadBitmap("toolbar-matrix.png"),
    })
end
return {
    init = init
}
