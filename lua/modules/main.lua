local FAILSAFE = 1
local TELEMETRY = 2

local RF_TUNE_OPTION = {name="RF Tune", min=-128, max=127, display=function(value) return value end }
local SERVO_REFRESH_RATE_OPTION = {name="Servo Refresh Rate", min=0, max=70, display=function(value) return (value * 5 + 50) .. "Hz" end }

local function init()
    -- ImmersionRC Ghost protocol
    system.registerGhostProtocol()

    -- Multimodule protocols
    system.registerMultimoduleProtocol("Assan", 24)
    system.registerMultimoduleProtocol("Devo", 7, {"8CH", "10CH", "12CH", "6CH", "7CH"})
    system.registerMultimoduleProtocol("DSM", 6, {"DSM2-1F", "DSM2-2F", "DSMX-1F", "DSMX-2F", "AUTO", "DSMR-1F"})
    system.registerMultimoduleProtocol("FlySky", 1, {"Default", "V9X9", "V6X6", "V912", "CX20"})
    system.registerMultimoduleProtocol("Frsky D8", 3)
    system.registerMultimoduleProtocol("Frsky V", 25)
    system.registerMultimoduleProtocol("FlySky AFHDS 2A", 28, {"PWM+IBUS", "PPM+IBUS", "PWM+SBUS", "PPM+SBUS", "PWM+IBUS16", "PPM+IBUS16"}, FAILSAFE + TELEMETRY, {SERVO_REFRESH_RATE_OPTION})
    system.registerMultimoduleProtocol("Hubsan", 2, {"H107", "H301", "H501"})
    system.registerMultimoduleProtocol("OMP", 77, {}, TELEMETRY, {RF_TUNE_OPTION})
end

return {init=init}
