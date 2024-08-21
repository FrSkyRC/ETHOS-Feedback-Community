-- Lua Source Example

local translations = {en="Lua Source", fr="Source Lua"}

local function sourceName(source)
  local locale = system.getLocale()
  return translations[locale] or translations["en"]
end

local function sourceInit(source)
  print("Source init")
  source:decimals(2)
  source:unit(UNIT_VOLT)
  source:value(0.0)
end

local function sourceReset(source)
  print("Source reset")
  source:value(0.0)
end

local function sourceRead(source)
  print("Source read")
  source:value(storage.read("Some Key"))
end

local function sourceWrite(source)
  print("Source write")
  storage.write("Some Key", source:value())
end

local function sourceWakeup(source)
  -- print("Source wakeup")
  source:value(source:value() + 0.1)
end

local function sourceConfigure(source)
end

local function init()
  system.registerSource({key="Example", name=sourceName, init=sourceInit, reset=sourceReset, wakeup=sourceWakeup, configure=sourceConfigure, read=sourceRead, write=sourceWrite})
end

return {init=init}
