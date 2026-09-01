local locale = system.getLocale()
local sysInfo = system.getVersion()

print("Get system language flag: ", locale)

local function greaterThan170()
  if sysInfo.major > 1 then
    return true
  elseif sysInfo.minor >= 7 then
    return true
  end
  return false
end

local i18nMap = {
  en = assert(loadfile("i18n/en.lua"))(),
}

local i18nFiles = system.listFiles("i18n")
if locale ~= 'cn' or greaterThan170() then
  for _, value in ipairs(i18nFiles) do
    if value == (locale .. ".lua") then
      i18nMap[locale] = assert(loadfile("i18n/" .. locale .. ".lua"))()
      break
    end
  end
end

local function translate(key, paramTable)
  local map = i18nMap[locale] or i18nMap['en']
  local string = map[key] or i18nMap['en'][key]
  if paramTable ~= nil and type(paramTable) == 'table' then
    string = string:gsub("{{%s*(%w+)%s*}}", function(replacement)
      return tostring(paramTable[replacement] or "")
    end)
  end
  return string
end

return { translate = translate }
