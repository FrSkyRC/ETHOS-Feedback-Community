-- Reusable lazy-loading helper.
--
-- Copy this file next to your script, then wrap registration callbacks with
-- lazy.wrap(). Only static metadata is kept in the startup file.

local lazy = {}

local function createModuleCaller(path)
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

  return function(method, ...)
    local mod = loadModule()
    local fn = mod and mod[method]
    if type(fn) == "function" then
      return fn(...)
    end
  end
end

local function makeProxy(call, method, fallback)
  return function(...)
    local result = call(method, ...)
    if result ~= nil then
      return result
    end

    local value = fallback and fallback[method]
    if type(value) == "function" then
      return value(...)
    end
    return value
  end
end

function lazy.wrap(registration, path, callbacks, fallback)
  local call = createModuleCaller(path)

  for i = 1, #callbacks do
    local method = callbacks[i]
    registration[method] = makeProxy(call, method, fallback)
  end

  return registration
end

return lazy
