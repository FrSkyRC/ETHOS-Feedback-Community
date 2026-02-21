-- Example usage of ethos_events.lua

local events = require("ethos_events")

local function create()
    return {}
end

local function event(widget, category, value, x, y)
    -- Print readable event names + numeric codes
    events.debug("example", category, value, x, y)
end

local function init()
    system.registerSystemTool({
        name = "Ethos Events Example",
        create = create,
        event = event
    })
end

return {init = init}
