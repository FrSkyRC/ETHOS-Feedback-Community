local config = {}
config.moduleName = "ELRS Configuration"
config.moduleDir = "/scripts/elrs/"
config.useCompiler = true

compile = assert(loadfile(config.moduleDir .. "compile.lua"))(config)
elrs = assert(compile.loadScript(config.moduleDir .. "elrs.lua"))(config, compile)


local function create()
    return elrs.create()
end

local function wakeup()
    return elrs.wakeup()
end

local function event(widget, category, value, x, y)
    return elrs.event(widget, category, value, x, y)
end

local function close()
    return elrs.close()
end

local function init()
  system.registerElrsModule({configure={name=config.moduleName, create=create, wakeup=wakeup,event=event,close=close}})
end

return {init=init}
