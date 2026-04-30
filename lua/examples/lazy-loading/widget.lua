-- registerWidget lazy-loading demo.
--
-- This file is intentionally small. It registers metadata immediately and
-- defers the real callbacks to widget_impl.lua.

local lazy = assert(loadfile("lazy.lua"))()

local widget = lazy.wrap({
  key = "lazy",
  name = "Lua Lazy Widget",
}, "widget_impl.lua", {"create", "paint", "wakeup", "configure", "read", "write", "close"}, {
  create = function() return {} end,
})

local function init()
  system.registerWidget(widget)
end

return {init = init}
