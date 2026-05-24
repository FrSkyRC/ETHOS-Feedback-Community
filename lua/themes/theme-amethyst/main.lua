-- @author flyingeek
-- more widgets on my github page https://github.com/flyingeek
--
local function init()
    system.registerTheme({
        key = "Amethys",
        name = "Amethyst",
        roundButtons = true,
        focusStyle = "invert",
        colors = {
            lcd.RGB(0xF0, 0xE6, 0xFF), -- PRIMARY_COLOR (violet white)
            lcd.RGB(0x2D, 0x16, 0x54), -- SECONDARY_BGCOLOR (dark violet panel)
            lcd.RGB(0xBF, 0x00, 0xFF), -- HIGHLIGHT_COLOR (vivid electric violet)
            lcd.RGB(0x0D, 0x02, 0x21), -- HIGHLIGHT_CONTRASTING_COLOR (very dark violet)
            lcd.RGB(0x6B, 0x4D, 0x8A), -- DISABLE_COLOR (desaturated violet)
            lcd.RGB(0x0D, 0x02, 0x21), -- PRIMARY_BGCOLOR (near-black violet background)
            COLOR_BLACK,               -- OVERLAY_COLOR
            lcd.RGB(0xC4, 0xAE, 0xFF), -- SECONDARY_COLOR (lavender)
            lcd.RGB(0x00, 0xFF, 0xCC), -- SAFE_COLOR (neon cyan)
            lcd.RGB(0x1A, 0x0A, 0x38), -- PAGE_BGCOLOR (dark violet page)
            lcd.RGB(0xFF, 0x2D, 0x55), -- ERROR_COLOR (vivid pink-red)
            lcd.RGB(0x00, 0xFF, 0xCC), -- ACTIVE_COLOR (neon cyan)
            lcd.RGB(0xC4, 0xAE, 0xFF), -- INACTIVE_COLOR (lavender)
            lcd.RGB(0xFF, 0x00, 0xCC), -- BUTTON_BORDER_ACTIVE_COLOR (neon magenta)
            lcd.RGB(0x3D, 0x20, 0x60), -- BUTTON_BORDER_COLOR (dark violet)
            lcd.RGB(0xFF, 0x95, 0x00), -- WARNING_COLOR (vivid amber — 9.4:1 on PRIMARY, 7.5:1 on SECONDARY)
            COLOR_BLACK,               -- SAFE_CONTRASTING_COLOR
            COLOR_BLACK,               -- TOPLCD_BGCOLOR (XE/S)
        },
        --toolbarLogo = "none",
        toolbarBackground = lcd.loadBitmap("toolbar-amethyst.png")
    })
end
return {
    init = init
}
