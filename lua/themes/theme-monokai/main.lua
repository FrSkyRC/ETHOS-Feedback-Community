-- @author flyingeek
-- more widgets on my github page https://github.com/flyingeek
--
local function init()
    system.registerTheme({
        key = "Monokai",
        name = "Monokai",
        roundButtons = true,
        focusStyle = "invert",
        colors = {
            lcd.RGB(0xF8, 0xF8, 0xF2), -- 1  PRIMARY_COLOR           (Monokai foreground — lum 0.932)
            lcd.RGB(0x49, 0x48, 0x3E), -- 2  SECONDARY_BGCOLOR        (warm olive panel — lum 0.047, 4.2× ratio)
            lcd.RGB(0x66, 0xD9, 0xE8), -- 3  HIGHLIGHT_COLOR          (Monokai cyan — lum 0.567, 10.1:1 on canvas)
            lcd.RGB(0x1A, 0x1B, 0x16), -- 4  HIGHLIGHT_CONTRASTING_COLOR (near-black — 11.3:1 on cyan)
            lcd.RGB(0x75, 0x71, 0x5E), -- 5  DISABLE_COLOR            (Monokai comment gray — 3.1:1 on canvas)
            lcd.RGB(0x27, 0x28, 0x22), -- 6  PRIMARY_BGCOLOR          (Monokai background — lum 0.011)
            COLOR_BLACK,               -- 7  OVERLAY_COLOR
            lcd.RGB(0xCF, 0xCF, 0xC2), -- 8  SECONDARY_COLOR          (warm light gray — 10.6:1 on canvas)
            lcd.RGB(0xA6, 0xE2, 0x2E), -- 9  SAFE_COLOR               (Monokai lime green — 10.8:1 on canvas)
            lcd.RGB(0x1E, 0x1F, 0x1A), -- 10 PAGE_BGCOLOR             (darker warm near-black — lum 0.006)
            lcd.RGB(0xF9, 0x26, 0x72), -- 11 ERROR_COLOR              (Monokai pink-red — 4.4:1 on canvas, 4.8:1 on page)
            lcd.RGB(0xE6, 0xDB, 0x74), -- 12 ACTIVE_COLOR             (Monokai yellow — 12.9:1 on page)
            lcd.RGB(0x75, 0x71, 0x5E), -- 13 INACTIVE_COLOR           (comment gray — 3.4:1 on page)
            lcd.RGB(0x66, 0xD9, 0xE8), -- 14 BUTTON_BORDER_ACTIVE_COLOR (matches HIGHLIGHT)
            lcd.RGB(0x3D, 0x3C, 0x24), -- 15 BUTTON_BORDER_COLOR
            lcd.RGB(0xFD, 0x97, 0x1F), -- 16 WARNING_COLOR            (Monokai orange — 7.5:1 on canvas)
            lcd.RGB(0x1A, 0x1B, 0x16), -- 17 SAFE_CONTRASTING_COLOR   (near-black on lime)
            COLOR_BLACK,               -- 18 TOPLCD_BGCOLOR (XE/S)
        },
        --toolbarLogo = "none",
        toolbarBackground = lcd.loadBitmap("toolbar-monokai.png"),
    })
end
return {
    init = init
}
