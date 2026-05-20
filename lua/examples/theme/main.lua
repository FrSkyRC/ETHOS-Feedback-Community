-- Lua Theme example

local function init()
  -- Colors from Ethos 1.6.6
  system.registerTheme({
    key="Dark16", 
    name="Dark (Ethos 1.6)",
    roundButtons=false,
    focusStyle="invert",
    colors={
        WHITE, -- PRIMARY_COLOR
        lcd.GREY(0x40), -- SECONDARY_BGCOLOR
        YELLOW, -- HIGHLIGHT_COLOR (configurable)
        BLACK, -- HIGHLIGHT_INVERT_COLOR
        lcd.GREY(0x70), -- DISABLE_COLOR
        lcd.GREY(0x20), -- PRIMARY_BGCOLOR
        BLACK, -- OVERLAY_COLOR
        lcd.GREY(0xB0), -- SECONDARY_COLOR
        GREEN, -- MIXER_OUTPUT_COLOR 
        lcd.GREY(0x10), -- PAGE_BGCOLOR
        RED, -- WARNING_COLOR
        GREEN, -- ACTIVE_COLOR
        RED, -- INACTIVE_COLOR
        WHITE, -- BUTTON_BORDER_ACTIVE_COLOR
        lcd.GREY(0x20), -- BUTTON_BORDER_COLOR
        BLACK, -- TOPLCD_BGCOLOR (XE/S)
    },
    toolbarBackground=lcd.loadBitmap("./toolbar_background_16.png"),
  })

  -- Colors from the default Dark theme
  -- system.registerTheme({
  --   key="DarkCopy", 
  --   name="Dark (Copy)",
  --   roundButtons=true,
  --   focusStyle="invert",
  --   colors={
  --       WHITE, -- PRIMARY_COLOR
  --       lcd.RGB(0x29, 0x30, 0x3B), -- SECONDARY_BGCOLOR
  --       YELLOW, -- HIGHLIGHT_COLOR (configurable)
  --       BLACK, -- HIGHLIGHT_INVERT_COLOR
  --       lcd.GREY(0x90), -- DISABLE_COLOR
  --       lcd.RGB(0x1F, 0x22, 0x29), -- PRIMARY_BGCOLOR
  --       BLACK, -- OVERLAY_COLOR
  --       lcd.GREY(0xB0), -- SECONDARY_COLOR
  --       GREEN, -- MIXER_OUTPUT_COLOR 
  --       lcd.GREY(0x10), -- PAGE_BGCOLOR
  --       RED, -- WARNING_COLOR
  --       GREEN, -- ACTIVE_COLOR
  --       RED, -- INACTIVE_COLOR
  --       WHITE, -- BUTTON_BORDER_ACTIVE_COLOR
  --       lcd.RGB(0x45, 0x4E, 0x57), -- BUTTON_BORDER_COLOR
  --       BLACK, -- TOPLCD_BGCOLOR (XE/S)
  --   }
  -- })

  -- Colors from the default Light theme
  -- system.registerTheme({
  --   key="LighCopy", 
  --   name="Light (Copy)",
  --   roundButtons=true,
  --   focusStyle="invert",
  --   colors={
  --       lcd.RGB(0x59, 0x57, 0x58), -- PRIMARY_COLOR
  --       lcd.GREY(0xCA), -- SECONDARY_BGCOLOR
  --       ORANGE, -- HIGHLIGHT_COLOR (configurable)
  --       WHITE, -- HIGHLIGHT_INVERT_COLOR
  --       lcd.GREY(0x90), -- DISABLE_COLOR
  --       lcd.RGB(0xD6, 0xD6, 0xD6), -- PRIMARY_BGCOLOR
  --       lcd.GREY(0x60), -- OVERLAY_COLOR
  --       lcd.RGB(0x75, 0x75, 0x75), -- SECONDARY_COLOR
  --       lcd.RGB(0x10, 0x40, 0xE0), -- MIXER_OUTPUT_COLOR 
  --       lcd.RGB(0xED, 0xEC, 0xF1), -- PAGE_BGCOLOR
  --       RED, -- WARNING_COLOR
  --       GREEN, -- ACTIVE_COLOR
  --       RED, -- INACTIVE_COLOR
  --       lcd.RGB(0x45, 0x4E, 0x57), -- BUTTON_BORDER_ACTIVE_COLOR
  --       lcd.GREY(0xA0), -- BUTTON_BORDER_COLOR
  --       WHITE, -- TOPLCD_BGCOLOR (XE/S)
  --   },
  --   toolbarBackground="light",
  --   toolbarLogo="light",
  -- })

  -- Colors from the default Dark theme, but with outline focus style (2px border width)
  system.registerTheme({
    key="DOutline", 
    name="Dark Outline",
    roundButtons=true,
    focusStyle="outline",
    borderWidth=2,
    colors={
        WHITE, -- PRIMARY_COLOR
        lcd.RGB(0x29, 0x30, 0x3B), -- SECONDARY_BGCOLOR
        YELLOW, -- HIGHLIGHT_COLOR (configurable)
        BLACK, -- HIGHLIGHT_INVERT_COLOR
        lcd.GREY(0x90), -- DISABLE_COLOR
        lcd.RGB(0x1F, 0x22, 0x29), -- PRIMARY_BGCOLOR
        BLACK, -- OVERLAY_COLOR
        lcd.GREY(0xB0), -- SECONDARY_COLOR
        GREEN, -- MIXER_OUTPUT_COLOR 
        lcd.GREY(0x10), -- PAGE_BGCOLOR
        RED, -- WARNING_COLOR
        GREEN, -- ACTIVE_COLOR
        RED, -- INACTIVE_COLOR
        WHITE, -- BUTTON_BORDER_ACTIVE_COLOR
        lcd.RGB(0x45, 0x4E, 0x57), -- BUTTON_BORDER_COLOR
        BLACK, -- TOPLCD_BGCOLOR (XE/S)
    }
  })
end

return {init=init}
