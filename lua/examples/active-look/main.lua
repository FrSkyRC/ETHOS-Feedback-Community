-- Lua ActiveLook glasses test

local function create()
    return {layout=nil, armed=false}
end

local function build(context)
    w, h = glasses.getWindowSize()
    context.layout = glasses.createLayout({x=10, y=10, w=w-20, h=h-20, bitmap={id=10, x=10, y=10}, text={x=10, y=60, font=1}, border=true})
    context.armed = false
end

local function wakeup(context)
    if context.layout ~= nil and context.armed == false then
        context.layout:clearAndDisplayExtended({x=10, y=10, text="text", commands={
             {text={text="extra text 1", font=2, x=10, y=80}},
             {text={text="extra text 2", font=3, x=10, y=110}},
             {bitmap={id=10, x=80, y=10}}
        }})
        glasses.bitmap(150, 20, 10) -- out of layout bitmap
        glasses.text(70, 70, 1, "out of layout text")
        context.armed = true
    end
end

local function init()
    system.registerGlassesWidget({key="engo", name="ActiveLook Lua", create=create, build=build, wakeup=wakeup})
end

return {init=init}
