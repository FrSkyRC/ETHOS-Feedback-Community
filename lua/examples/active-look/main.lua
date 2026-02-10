-- Lua ActiveLook glasses test

local function create()
    return {layout=nil, armed=false}
end

local function build(context)
    context.layout = glasses.createLayout({bitmap={id=10, x=10, y=10}, text={x=10, y=100}, border=true})
    context.armed = false
end

local function wakeup(context)
    if context.layout ~= nil and context.armed == false then
        glasses.layoutClearAndDisplay(context.layout, "ARMED!")
        context.armed = true
    end
end

local function init()
    system.registerGlassesWidget({key="engo", name="ActiveLook Lua", create=create, build=build, wakeup=wakeup})
end

return {init=init}
