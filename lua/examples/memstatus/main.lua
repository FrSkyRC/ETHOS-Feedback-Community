-- Simple script that can run as a background task.
-- it will print out memory status to the console every 
-- 5 seconds (or whatever interval you set)
-- this is helpfull when building memory sensitive scripts
-- as it can aid tracking down memory intensive code.


local config = {}
config.taskName = "MemStatus"
config.taskKey = "memstat"

local interval = 5
local wakeupScheduler = os.clock()
local mem

prevluaRamAvailable = 0
prevluaBitmapsRamAvailable = 0



function wakeup()

    local now = os.clock()

    if (now - wakeupScheduler) >= interval then
        wakeupScheduler = now
		
		mem = system.getMemoryUsage()

		local ramDiff = (mem.luaRamAvailable - prevluaRamAvailable)/1000 .. 'KB'
		local bmpDiff = (mem.luaBitmapsRamAvailable - prevluaBitmapsRamAvailable)/1000 .. 'KB'

		prevluaRamAvailable = mem.luaRamAvailable
		prevluaBitmapsRamAvailable = mem.luaBitmapsRamAvailable
		

		print("-------------------------------------------------------") 
		print("luaRamAvailable        : " .. mem.luaRamAvailable/1000 .. "KB" .. " ["..ramDiff.."]" )		
		print("luaBitmapsRamAvailable : " .. mem.luaBitmapsRamAvailable/1000 .. "KB" .. " ["..bmpDiff.."]" )
		print("------------------------------------------------------\r\n") 

    end


end


local function init()
    system.registerTask({name = config.taskName, key = config.taskKey, wakeup = wakeup})
end

return {init = init}
