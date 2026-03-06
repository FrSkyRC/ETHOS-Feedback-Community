-- Lua Latency Test

local icon = lcd.loadMask("latency.png")
local latencyTestInProgress = false

Latency = {}
Latency.__index = Latency

function Latency:new()
    return setmetatable({
        min = math.huge,
        max = 0,
        sum = 0,
        count = 0
    }, Latency)
end

function Latency:reset()
    self.sum = 0
    self.count = 0
    self.min = math.huge
    self.max = 0
end

function Latency:add(value)
    self.sum = self.sum + value
    self.count = self.count + 1
    if value < self.min then
        self.min = value
    end
    if value > self.max then
        self.max = value
    end
end

function Latency:display()
    return "avg: " .. (self.sum / self.count / 1000) .. "ms min: " .. (self.min / 1000) .. "ms max: " .. (self.max / 1000) .. "ms count: " .. self.count .. "samples"
end
    
local mixerLatency = Latency:new()
local sbusLatency = Latency:new()
local totalLatency = Latency:new()

local function create()
    latencyTestInProgress = false
    mixerLatency:reset()
    sbusLatency:reset()
    totalLatency:reset()
    return nil
end

local function wakeup()   
    if latencyTestInProgress then
        local result = system.getLatencyTestResult()
        if result ~= nil then
            mixerLatency:add(result.mixer)
            sbusLatency:add(result.sbus)
            totalLatency:add(result.total)
            lcd.invalidate()            
            latencyTestInProgress = false
        end
    else
        -- moves CH1 to 100% during 50ms
        system.startLatencyTest(0, 100, 50)
        latencyTestInProgress = true
    end
end

local function paint()
    if totalLatency.count > 0 then
        lcd.drawText(10, 100, "Mixer ... " .. mixerLatency:display())
        lcd.drawText(10, 150, "SBus ... " .. sbusLatency:display())
        lcd.drawText(10, 200, "Total ... " .. totalLatency:display())
    else
        lcd.drawText(00, 100, "Waiting... ")
    end
end

local function init()
    system.registerSystemTool({name="Latency Test", icon=icon, create=create, wakeup=wakeup, paint=paint})
end

return {init=init}
