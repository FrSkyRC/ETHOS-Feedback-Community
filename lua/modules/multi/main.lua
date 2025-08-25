-- Multimodule protocols

local FAILSAFE = 1

-- options sent on byte 26
local DISABLE_TELEMETRY_OPTION = {name="Disable telemetry", type="checkbox", min=0, max=0x02000000}
local DISABLE_CH_MAPPING_OPTION = {name="Disable channel mapping", type="checkbox", min=0, max=0x01000000}

-- options sent on byte 1
local BIND_ON_CHANNEL_OPTION = {name="Bind on channel", type="checkbox", min=0, max=0x400000}

-- options sent on byte 2
local LOW_POWER_OPTION = {name="Low power", type="checkbox", min=0, max=0x8000}

-- options sent on byte 3
local RF_TUNE_OPTION = {name="RF tune", min=-128, max=127}
local DSM2_ENABLE_MAX_THROW_OPTION = {name="Enable max throw", type="checkbox", min=0, max=0x80}
local DSM2_SERVO_REFRESH_RATE_OPTION = {name="Servo refresh rate", type="choice", max=0x40, values={{"22ms", 0x00}, {"11ms", 0x40}}}
local FLYSKY_SERVO_REFRESH_RATE_OPTION = {name="Servo refresh rate", min=0, max=70, display=function(value) return (value * 5 + 50) .. "Hz" end}
local FIXED_ID = {name="Fixed ID", type="checkbox", min=0, max=0x00000001}

local function init()
    system.registerMultimoduleProtocol("Assan", 24, {options={BIND_ON_CHANNEL_OPTION, DISABLE_TELEMETRY_OPTION, LOW_POWER_OPTION}})
    system.registerMultimoduleProtocol("Bayang", 14, {variants={"Bayang", "H8S3D", "X16_AH", "IRDRONE", "DHD_D4", "QX100"}})
    system.registerMultimoduleProtocol("Bayang RX", 59, {variants={"Multi", "CPPM"}})
    system.registerMultimoduleProtocol("Bugs", 41)
    system.registerMultimoduleProtocol("BugsMini", 42, {variants={"BUGSMINI", "BUGS3H"}})
    system.registerMultimoduleProtocol("Cabell", 34, {variants={"Cabell_V3", "C_TELEM", "0", "0", "0", "0", "F_SAFE", "UNBIND"}})
    system.registerMultimoduleProtocol("CFlie", 38, {variants={"CFlie"}})
    system.registerMultimoduleProtocol("CG023", 13, {variants={"CG023", "YD829"}})
    system.registerMultimoduleProtocol("Corona", 37, {variants={"COR_V1", "COR_V2", "FD_V3"}, options={RF_TUNE_OPTION}})
    system.registerMultimoduleProtocol("CX10", 12, {variants={"GREEN", "BLUE", "DM007", "0", "J3015_1", "J3015_2", "MK33041"}})
    system.registerMultimoduleProtocol("Devo", 7, {variants={"8CH", "10CH", "12CH", "6CH", "7CH"}, options={FIXED_ID}})
    system.registerMultimoduleProtocol("DM002", 33)
    system.registerMultimoduleProtocol("DSM_RX", 70, {variants={"Multi", "CPPM"}})
    system.registerMultimoduleProtocol("E010R5", 81)
    system.registerMultimoduleProtocol("E016H", 85)
    system.registerMultimoduleProtocol("E016HV2", 80)
    system.registerMultimoduleProtocol("E01X", 45, {variants={"E012", "E015"}})
    system.registerMultimoduleProtocol("E129", 83, {variants={"E129", "C186"}})
    system.registerMultimoduleProtocol("ESky", 16, {variants={"ESky", "ET4"}})
    system.registerMultimoduleProtocol("ESky150", 35)
    system.registerMultimoduleProtocol("ESky150V2", 69)
    system.registerMultimoduleProtocol("FlySky", 1, {variants={"Default", "V9X9", "V6X6", "V912", "CX20"}})
    system.registerMultimoduleProtocol("FlySky AFHDS 2A", 28, {variants={"PWM+IBUS", "PPM+IBUS", "PWM+SBUS", "PPM+SBUS", "PWM+IBUS16", "PPM+IBUS16"}, features=FAILSAFE, options={FLYSKY_SERVO_REFRESH_RATE_OPTION}})
    system.registerMultimoduleProtocol("Flysky AFHDS2A RX", 56, {variants={"Multi", "CPPM"}})
    system.registerMultimoduleProtocol("FQ777", 23)
    system.registerMultimoduleProtocol("FrSky D8", 3, {variants={"D8", "Cloned"}, options={RF_TUNE_OPTION}, minChannels=8, maxChannels=8})
    system.registerMultimoduleProtocol("FrskyL", 67, {variants={"LR12", "LR12 6CH"}})
    system.registerMultimoduleProtocol("FrSky V", 25, {options={RF_TUNE_OPTION}})
    system.registerMultimoduleProtocol("FrskyX", 15, {variants={"CH_16", "CH_8", "EU_16", "EU_8", "Cloned", "Cloned_8"}, options={RF_TUNE_OPTION}})
    system.registerMultimoduleProtocol("FrskyX2", 64, {variants={"CH_16", "CH_8", "EU_16", "EU_8", "Cloned", "Cloned_8"}, features=FAILSAFE, options={RF_TUNE_OPTION}})
    system.registerMultimoduleProtocol("Frsky_RX", 55, {variants={"Multi", "CloneTX", "EraseTX", "CPPM"}})
    system.registerMultimoduleProtocol("Futaba/SFHSS", 21, {variants={"SFHSS"}, options={RF_TUNE_OPTION}})
    system.registerMultimoduleProtocol("FX", 28, {variants={"816", "620", "9630", "Q560", "QF012"}})
    system.registerMultimoduleProtocol("FY326", 20, {variants={"FY326", "FY319"}})
    system.registerMultimoduleProtocol("GD00X", 47, {variants={"GD_V1*", "GD_V2*"}})
    system.registerMultimoduleProtocol("Graupner HoTT", 57, {variants={"Sync", "No_Sync"}, options={RF_TUNE_OPTION}})
    system.registerMultimoduleProtocol("GW008", 32)
    system.registerMultimoduleProtocol("H8_3D", 36, {variants={"H8_3D", "H20H", "H20Mini", "H30Mini"}})
    system.registerMultimoduleProtocol("Height", 53, {variants={"5ch", "8ch"}})
    system.registerMultimoduleProtocol("Hisky", 4, {variants={"Hisky", "HK310"}})
    system.registerMultimoduleProtocol("Hitec", 39, {variants={"OPT_FW", "OPT_HUB", "MINIMA"}, options={RF_TUNE_OPTION}})
    system.registerMultimoduleProtocol("Hontai", 26, {variants={"HONTAI", "JJRCX1", "X5C1", "FQ777_951"}})
    system.registerMultimoduleProtocol("Hubsan", 2, {variants={"H107", "H301", "H501"}})
    system.registerMultimoduleProtocol("J6Pro", 22)
    system.registerMultimoduleProtocol("JJRC345", 71, {variants={"JJRC345", "SkyTmblr"}})
    system.registerMultimoduleProtocol("JOYSWAY", 84)
    system.registerMultimoduleProtocol("KF606", 49, {variants={"KF606", "MIG320"}})
    system.registerMultimoduleProtocol("KN", 9, {variants={"WLTOYS", "FEILUN"}})
    system.registerMultimoduleProtocol("Kyosho", 73, {variants={"FHSS", "Hype"}})
    system.registerMultimoduleProtocol("Kyosho2", 93, {variants={"KT-17"}})
    system.registerMultimoduleProtocol("LOLI", 82)
    system.registerMultimoduleProtocol("Losi", 89)
    system.registerMultimoduleProtocol("MJXq", 18, {variants={"WLH08", "X600", "X800", "H26D", "E010*", "H26WH", "PHOENIX*"}})
    system.registerMultimoduleProtocol("MPX MLINK", 78, {options={BIND_ON_CHANNEL_OPTION, DISABLE_TELEMETRY_OPTION, LOW_POWER_OPTION}, features=FAILSAFE})
    system.registerMultimoduleProtocol("MouldKg", 90, {variants={"Analog", "Digit"}})
    system.registerMultimoduleProtocol("MT99xx", 17, {variants={"MT", "H7", "YZ", "LS", "FY805", "A180", "DRAGON", "F949G"}})
    system.registerMultimoduleProtocol("MT99xx2", 92, {variants={"PA18"}})
    system.registerMultimoduleProtocol("NCC1701", 44)
    system.registerMultimoduleProtocol("OMP", 77, {options={RF_TUNE_OPTION}})
    system.registerMultimoduleProtocol("OpenLRS", 27)
    system.registerMultimoduleProtocol("Pelikan", 60, {variants={"Pro", "Lite", "SCX24"}})
    system.registerMultimoduleProtocol("Potensic", 51, {variants={"A20"}})
    system.registerMultimoduleProtocol("PROPEL", 66, {variants={"74-Z"}})
    system.registerMultimoduleProtocol("Q2X2", 29, {variants={"Q222", "Q242", "Q282"}})
    system.registerMultimoduleProtocol("Q303", 31, {variants={"Q303", "CX35", "CX10D", "CX10WD"}})
    system.registerMultimoduleProtocol("Q90C", 72, {variants={"Q90C*"}})
    system.registerMultimoduleProtocol("RadioLink", 74, {variants={"Surface", "Air", "DumboRC"}})
    system.registerMultimoduleProtocol("Realacc", 76, {variants={"R11"}})
    system.registerMultimoduleProtocol("Redpine", 50, {variants={"FAST", "SLOW"}})
    system.registerMultimoduleProtocol("Scanner", 54)
    system.registerMultimoduleProtocol("Shenqi", 19, {variants={"Shenqi"}})
    system.registerMultimoduleProtocol("Skyartec", 68)
    system.registerMultimoduleProtocol("SLT", 11, {variants={"SLT_V1", "SLT_V2", "Q100", "Q200", "MR100"}})
    system.registerMultimoduleProtocol("Spektrum", 6, {variants={"DSM2-1F", "DSM2-2F", "DSMX-1F", "DSMX-2F", "AUTO", "DSMR-1F"}, minChannels=3, maxChannels=12, options={DSM2_ENABLE_MAX_THROW_OPTION, DSM2_SERVO_REFRESH_RATE_OPTION, DISABLE_TELEMETRY_OPTION, DISABLE_CH_MAPPING_OPTION, LOW_POWER_OPTION}})
    system.registerMultimoduleProtocol("SymaX", 10, {variants={"SYMAX", "SYMAX5C"}})
    system.registerMultimoduleProtocol("Tiger", 61)
    system.registerMultimoduleProtocol("Traxxas", 43, {variants={"6519 RX"}})
    system.registerMultimoduleProtocol("V2x2", 5, {variants={"V2x2", "JXD506", "MR101"}})
    system.registerMultimoduleProtocol("V761", 48, {variants={"3CH", "4CH", "TOPRC"}})
    system.registerMultimoduleProtocol("V911S", 46, {variants={"V911S*", "E119*"}})
    system.registerMultimoduleProtocol("WFLY", 40, {variants={"WFR0x"}})
    system.registerMultimoduleProtocol("WFLY2", 79, {variants={"RF20x"}})
    system.registerMultimoduleProtocol("WK2x01", 30, {variants={"WK2801", "WK2401", "W6_5_1", "W6_6_1", "W6_HEL", "W6_HEL_I"}})
    system.registerMultimoduleProtocol("XERALL", 91, {variants={"Tank"}})
    system.registerMultimoduleProtocol("XK", 62, {variants={"X450", "X420"}})
    system.registerMultimoduleProtocol("XK2", 99, {variants={"X4", "P10"}})
    system.registerMultimoduleProtocol("YD717", 8, {variants={"YD717", "SKYWLKR", "SYMAX4", "XINXUN", "NIHUI"}})
    system.registerMultimoduleProtocol("ZSX", 52, {variants={"280"}})
end

return {init=init}
