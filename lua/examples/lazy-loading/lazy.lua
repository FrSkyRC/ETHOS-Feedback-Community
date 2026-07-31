-- Reusable lazy-loading helper.
--
-- Copy this file next to your script, then wrap registration callbacks with
-- lazy.wrap(). Only static metadata is kept in the startup file.
--
-- IMPORTANT: read the README's "Known limitations" section before using
-- this for a widget's or system tool's *top-level* registration. Deferring
-- top-level registerWidget()/registerSystemTool() callbacks behind a proxy
-- layer like this one has been tried and reverted in at least one
-- production Ethos Lua suite after on-device testing showed it increased
-- retained RAM over a session compared to registering the real callbacks
-- directly -- confirm the tradeoff on your own target hardware before
-- relying on it for something the pilot uses every session.
--
-- The proxy below is self-eliminating: the *first* call to any wrapped
-- method pays the loadfile() + table-lookup indirection cost, and that
-- same call replaces every wrapped method on `registration` with the real
-- module's function (or the fallback, if loading failed) so every call
-- after the first goes straight to the real function with no further
-- proxy overhead. This matters for hot paths like paint()/wakeup(), which
-- Ethos calls on every frame/tick for as long as the widget is visible --
-- without self-elimination, *every one* of those calls, for the widget's
-- entire remaining lifetime, would pay the extra indirection, not just
-- the first.

local lazy = {}

local function createModuleLoader(path)
  local module = nil
  local attempted = false

  -- Returns (module, justCompleted). justCompleted is true exactly once,
  -- on whichever call actually performs the load attempt (success or
  -- failure) -- callers use it to know when it's safe to resolve every
  -- wrapped method to its final, direct implementation.
  return function()
    if attempted then
      return module, false
    end
    attempted = true

    local chunk, err = loadfile(path)
    if not chunk then
      print("Lazy load failed: " .. path .. " (" .. tostring(err) .. ")")
      return nil, true
    end

    local ok, result = pcall(chunk)
    if not ok then
      print("Lazy module errored: " .. path .. " (" .. tostring(result) .. ")")
      return nil, true
    end

    if type(result) ~= "table" then
      print("Lazy module did not return a table: " .. path)
      return nil, true
    end

    module = result
    print("Lazy loaded: " .. path)
    return module, true
  end
end

-- Overwrites every wrapped method on `registration` with its final,
-- direct implementation (module function, or fallback if the module
-- didn't provide one / failed to load). Methods with neither are left
-- as-is (still the proxy, which will keep returning nil harmlessly).
local function resolveRegistration(registration, callbacks, fallback, mod)
  for i = 1, #callbacks do
    local method = callbacks[i]
    local fn = mod and mod[method]
    if type(fn) ~= "function" and fallback then
      fn = fallback[method]
    end
    if fn ~= nil then
      registration[method] = fn
    end
  end
end

local function makeProxy(loadModule, method, fallback, onResolved)
  return function(...)
    local mod, justCompleted = loadModule()
    if justCompleted then
      onResolved(mod)
    end

    local fn = mod and mod[method]
    if type(fn) ~= "function" and fallback then
      fn = fallback[method]
    end
    if type(fn) == "function" then
      return fn(...)
    end
    return fn
  end
end

function lazy.wrap(registration, path, callbacks, fallback)
  local loadModule = createModuleLoader(path)

  local function onResolved(mod)
    resolveRegistration(registration, callbacks, fallback, mod)
  end

  for i = 1, #callbacks do
    local method = callbacks[i]
    registration[method] = makeProxy(loadModule, method, fallback, onResolved)
  end

  return registration
end

return lazy
