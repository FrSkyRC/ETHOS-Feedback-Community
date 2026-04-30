-- Lua Lazy Loading example
--
-- main.lua only loads the tiny registration demos. The heavier callback
-- implementations are loaded lazily by tool.lua and widget.lua.

local toolDemo = assert(loadfile("tool.lua"))()
local widgetDemo = assert(loadfile("widget.lua"))()

local function init()
  toolDemo.init()
  widgetDemo.init()
end

return {init = init}
