-- registerSystemTool lazy-loading demo.
--
-- This file is intentionally small. It registers metadata immediately and
-- defers the real callbacks to tool_impl.lua.

local lazy = assert(loadfile("lazy.lua"))()

local tool = lazy.wrap({
  name = "Lua Lazy Tool",
}, "tool_impl.lua", {"create", "wakeup", "event", "close"})

local function init()
  system.registerSystemTool(tool)
end

return {init = init}
