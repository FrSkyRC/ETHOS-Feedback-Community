-- Lua Sinus widget

local translations = {en="Lua Sinus", fr="Sinus Lua"}

local function name(widget)
    local locale = system.getLocale()
    return translations[locale] or translations["en"]
end

local function create()
    return {color=lcd.RGB(0, 0, 255)}
end

local function paint(widget)
    local w, h = lcd.getWindowSize()
    lcd.drawLine(0, h/2, w, h/2)
    lcd.color(widget.color)
    for i = 0,w do
      local val = math.sin(i*math.pi/(w/2))
      lcd.drawPoint(i, val*h/2+h/2)
    end
end

local function menu(widget)
    return {
        {"Model Info", function()
                         local buttons = { {label="Close", action=function() return true end},}
                         form.openDialog("Model Info", "Some Text", buttons)
                        end
        }
    }
end

local function init()
    system.registerWidget({key="sinus", name=name, create=create, paint=paint, menu=menu})
end

return {init=init}
