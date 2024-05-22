local environment = system.getVersion()

local function create(widget)
    return widget 
end

local function configure(widget)
    return widget
end

local function paint(widget)
	-- this is called wherver lcd.invalidate() is called.
	-- you use this loop to handle any display functions within
	-- your widget
end

local function menu(widget)
	-- add a menu item to the configuration menu popup of the widget
	-- usefull if adding new tools

	--return {
	--	  { "Entry 1", function() end},
	--	  { "Entry 2", function() end},
	--	}
end

local function read()
	-- read values from internal storage
	
	-- value = storage.read("slot")
	
	return true
end

local function write()
	-- write values from internal storage

	-- storage.write("slot", value)
	
	return true
end


local function event(widget, category, value, x, y)
	-- trigger whenever the widget is in focus and and
	-- even occurs such as a button or screen click
	print("Event received:", category, value, x, y)
	
	return true
end

local function wakeup(widget)
	-- this is the main loop that ethos calls every couple of ms
	
    return
end



local function init()
	-- this is where we 'setup' the widget
	
	local key = "abcdefg"			-- unique key - keep it less that 8 chars
	local name = "test project"		-- name of widget

    system.registerWidget(
        {
            key = key,					-- unique project id
            name = name,				-- name of widget
            create = create,			-- function called when creating widget
            configure = configure,		-- function called when configuring the widget (use ethos forms)
            paint = paint,				-- function called when lcd.invalidate() is called
            wakeup = wakeup,			-- function called as the main loop
            read = read,				-- function called when starting widget and reading configuration params
            write = write,				-- function called when saving values / changing values in the configuration menu
			event = event,				-- function called when buttons or screen clips occur
			menu = menu,				-- function called to add items to the menu
			persistent = false,			-- true or false to make the widget carry values between sessions and models (not safe imho)
        }
    )

end

return {init = init}
