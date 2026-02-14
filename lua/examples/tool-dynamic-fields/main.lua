-- Lua Dynamic Fields example
-- Demonstrates updating existing form fields with :step(), :minimum(),
-- :maximum(), :value(), :values(), and :suffix().

local translations = {en = "Lua Dynamic Fields"}
local icon = lcd.loadMask("form.png")

local function name()
    local locale = system.getLocale()
    return translations[locale] or translations.en
end

local state = {
    profileIndex = 1,
    altitude = 0,
    speed = 0,
    mode = 0
}

local fields = {}

local profiles = {
    {
        name = "Metric",
        altitude = {min = 0, max = 3000, step = 5, value = 120, suffix = "m"},
        speed = {min = 0, max = 250, step = 1, value = 65, suffix = "km/h"},
        modes = {
            values = {{"Eco", 0}, {"Cruise", 1}, {"Sport", 2}},
            value = 1
        }
    },
    {
        name = "Imperial",
        altitude = {min = 0, max = 10000, step = 25, value = 400, suffix = "ft"},
        speed = {min = 0, max = 160, step = 1, value = 40, suffix = "mph"},
        modes = {
            values = {{"Low", 0}, {"Medium", 1}, {"High", 2}},
            value = 2
        }
    },
    {
        name = "Precision",
        altitude = {min = -100, max = 100, step = 1, value = 0, suffix = "cm"},
        speed = {min = 0, max = 5000, step = 10, value = 1200, suffix = "mm/s"},
        modes = {
            values = {{"Hold", 0}, {"Track", 1}, {"Follow", 2}, {"Debug", 3}},
            value = 0
        }
    }
}

local function applyProfile(index)
    if index < 1 then
        index = #profiles
    elseif index > #profiles then
        index = 1
    end

    state.profileIndex = index
    local profile = profiles[index]

    state.altitude = profile.altitude.value
    state.speed = profile.speed.value
    state.mode = profile.modes.value

    if fields.profile and fields.profile.value then
        fields.profile:value("Active profile: " .. profile.name)
    end

    if fields.altitude then
        if fields.altitude.minimum then fields.altitude:minimum(profile.altitude.min) end
        if fields.altitude.maximum then fields.altitude:maximum(profile.altitude.max) end
        if fields.altitude.step then fields.altitude:step(profile.altitude.step) end
        if fields.altitude.suffix then fields.altitude:suffix(profile.altitude.suffix) end
        if fields.altitude.value then fields.altitude:value(profile.altitude.value) end
    end

    if fields.speed then
        if fields.speed.minimum then fields.speed:minimum(profile.speed.min) end
        if fields.speed.maximum then fields.speed:maximum(profile.speed.max) end
        if fields.speed.step then fields.speed:step(profile.speed.step) end
        if fields.speed.suffix then fields.speed:suffix(profile.speed.suffix) end
        if fields.speed.value then fields.speed:value(profile.speed.value) end
    end

    if fields.mode then
        if fields.mode.values then fields.mode:values(profile.modes.values) end
        if fields.mode.value then fields.mode:value(profile.modes.value) end
    end

    lcd.invalidate()
end

local function nextProfile()
    applyProfile(state.profileIndex + 1)
end

local function previousProfile()
    applyProfile(state.profileIndex - 1)
end

local function create()
    fields = {}

    local line = form.addLine("Profile")
    fields.profile = form.addStaticText(line, nil, "")

    line = form.addLine("Switch profile")
    local slots = form.getFieldSlots(line, {0, 0})
    form.addTextButton(line, slots[1], "Button 1", nextProfile)
    form.addTextButton(line, slots[2], "Button 2", previousProfile)

    line = form.addLine("Altitude")
    fields.altitude = form.addNumberField(
        line,
        nil,
        profiles[1].altitude.min,
        profiles[1].altitude.max,
        function() return state.altitude end,
        function(value) state.altitude = value end
    )

    line = form.addLine("Speed")
    fields.speed = form.addNumberField(
        line,
        nil,
        profiles[1].speed.min,
        profiles[1].speed.max,
        function() return state.speed end,
        function(value) state.speed = value end
    )

    line = form.addLine("Mode")
    fields.mode = form.addChoiceField(
        line,
        nil,
        profiles[1].modes.values,
        function() return state.mode end,
        function(value) state.mode = value end
    )

    applyProfile(1)
    return state
end

local function init()
    system.registerSystemTool({name = name, icon = icon, create = create})
end

return {init = init}
