-- Lua Wizard category example: a "Tank" category in the model wizard
-- (system.registerWizard()), next to Plane, Glider, Heli...
--
-- When it is chosen, the wizard shows the 2 pages below, then the model name:
--   1. Tracks: the speed and steering sources, and whether the tank has a turret
--   2. Turret: its rotation source (only when the tank has a turret)
-- The model is created with these mixes:
--   Track L = speed + steering
--   Track R = speed - steering
--   Turret  = turret source (optional)
--
-- To be copied in /scripts/wizard-tank/ (main.lua and tank.png) on the radio.

local icon = lcd.loadMask("tank.png")

local speedSource
local steeringSource
local hasTurret
local turretSource

-- Called each time the model wizard is opened: default values
local function wizardInit()
  speedSource = system.getSource({category=CATEGORY_ANALOG, member=ANALOG_STICK_ELEVATOR})
  steeringSource = system.getSource({category=CATEGORY_ANALOG, member=ANALOG_STICK_AILERON})
  hasTurret = false
  turretSource = system.getSource({category=CATEGORY_ANALOG, member=ANALOG_STICK_RUDDER})
end

-- The same source, inverted (OPTION_SOURCE_INVERT is the bit 0 of the source options)
local function inverted(source)
  return {category=source:category(), member=source:member(), options=source:options() ~ 1}
end

-- Page 1: tracks

local function buildTracksPage()
  local line = form.addLine("Speed")
  form.addSourceField(line, nil, function() return speedSource end, function(value) speedSource = value end)

  line = form.addLine("Steering")
  form.addSourceField(line, nil, function() return steeringSource end, function(value) steeringSource = value end)

  line = form.addLine("Turret")
  form.addBooleanField(line, nil, function() return hasTurret end, function(value) hasTurret = value end)
end

local function createTracksMixes()
  -- the steering is added to the speed on the left track, subtracted on the right one
  model.createMix("free", {name="Track L", input=speedSource, actions={{action="offset", active=steeringSource}}})
  model.createMix("free", {name="Track R", input=speedSource, actions={{action="offset", active=inverted(steeringSource)}}})
end

-- Page 2: turret (only when the tank has one)

local function turretAvailable()
  return hasTurret
end

local function buildTurretPage()
  local line = form.addLine("Turret rotation")
  form.addSourceField(line, nil, function() return turretSource end, function(value) turretSource = value end)
end

local function createTurretMix()
  model.createMix("free", {name="Turret", input=turretSource})
end

local function init()
  system.registerWizard("Tank", icon, {
    {init=wizardInit, build=buildTracksPage, run=createTracksMixes},
    {available=turretAvailable, build=buildTurretPage, run=createTurretMix},
  })
end

return {init=init}
