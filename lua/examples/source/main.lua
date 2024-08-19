-- Lua Source Example

local translations = {en="Lua Source", fr="Source Lua"}

local function name(widget)
  local locale = system.getLocale()
  return translations[locale] or translations["en"]
end

local function sourceInit(source)
  source:value(0.1)
  source:decimals(2)
  source:unit(UNIT_VOLT)
end

local function sourceWakeup(source)
  source:value(source:value() + 0.1)
end

local function init()
  system.registerSource({key="Example", name=name, init=sourceInit, wakeup=sourceWakeup})
end

return {init=init}
