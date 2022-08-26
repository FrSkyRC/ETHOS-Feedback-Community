local FAILSAFE = 1
local TELEMETRY = 2

local RF_TUNE_OPTION = {name="RF Tune", min=-128, max=127, display=function(value) return value end }
local SERVO_REFRESH_RATE_OPTION = {name="Servo Refresh Rate", min=0, max=70, display=function(value) return (value * 5 + 50) .. "Hz" end }

local function init()
    -- ImmersionRC Ghost protocol
    system.registerGhostProtocol()

    -- Multimodule protocols
    system.registerMultimoduleProtocol("Assan", 24)
    system.registerMultimoduleProtocol("Devo", 7, {variants={"8CH", "10CH", "12CH", "6CH", "7CH"}})
    system.registerMultimoduleProtocol("DSM", 6, {variants={"DSM2-1F", "DSM2-2F", "DSMX-1F", "DSMX-2F", "AUTO", "DSMR-1F"}, minChannels=3, maxChannels=12})
    system.registerMultimoduleProtocol("FlySky", 1, {variants={"Default", "V9X9", "V6X6", "V912", "CX20"}})
    system.registerMultimoduleProtocol("FrSky D8", 3, {minChannels=8, maxChannels=8})
    system.registerMultimoduleProtocol("FrSky V", 25)
    system.registerMultimoduleProtocol("FlySky AFHDS 2A", 28, {variants={"PWM+IBUS", "PPM+IBUS", "PWM+SBUS", "PPM+SBUS", "PWM+IBUS16", "PPM+IBUS16"}, features=FAILSAFE+TELEMETRY, options={SERVO_REFRESH_RATE_OPTION}})
    system.registerMultimoduleProtocol("Hubsan", 2, {variants={"H107", "H301", "H501"}})
    system.registerMultimoduleProtocol("OMP", 77, {features=TELEMETRY, options={RF_TUNE_OPTION}})
end

return {init=init}
