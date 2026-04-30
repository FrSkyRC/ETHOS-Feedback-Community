-- Lua Lazy Loading example
--
-- Keep main.lua cheap: register static metadata and small proxy callbacks.
-- tool.lua and widget.lua are loaded only when Ethos first uses them.

local function createLazyModule(path)
  local module = nil
  local failed = false

  local function loadModule()
    if module ~= nil then
      return module
    end
    if failed then
      return nil
    end

    local chunk, err = loadfile(path)
    if not chunk then
      failed = true
      print("Lazy load failed: " .. path .. " (" .. tostring(err) .. ")")
      return nil
    end

    local ok, result = pcall(chunk)
    if not ok then
      failed = true
      print("Lazy module errored: " .. path .. " (" .. tostring(result) .. ")")
      return nil
    end

    if type(result) ~= "table" then
      failed = true
      print("Lazy module did not return a table: " .. path)
      return nil
    end

    module = result
    print("Lazy loaded: " .. path)
    return module
  end

  local function call(method, ...)
    local mod = loadModule()
    local fn = mod and mod[method]
    if type(fn) == "function" then
      return fn(...)
    end
  end

  return call
end

local callTool = createLazyModule("tool.lua")
local callWidget = createLazyModule("widget.lua")

local function init()
  system.registerSystemTool({
    name = "Lua Lazy Tool",
    create = function(...) return callTool("create", ...) end,
    wakeup = function(...) return callTool("wakeup", ...) end,
    event = function(...) return callTool("event", ...) end,
    close = function(...) return callTool("close", ...) end,
  })

  system.registerWidget({
    key = "lazy",
    name = "Lua Lazy Widget",
    create = function(...) return callWidget("create", ...) or {} end,
    paint = function(...) return callWidget("paint", ...) end,
    wakeup = function(...) return callWidget("wakeup", ...) end,
    configure = function(...) return callWidget("configure", ...) end,
    read = function(...) return callWidget("read", ...) end,
    write = function(...) return callWidget("write", ...) end,
    close = function(...) return callWidget("close", ...) end,
  })
end

return {init = init}
