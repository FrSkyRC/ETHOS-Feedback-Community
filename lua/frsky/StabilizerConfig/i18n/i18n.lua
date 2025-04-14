local locale = system.getLocale()
print("Get system language flag: ", locale)

local i18nMap = {
  en = assert(loadfile(GlobalPath .. "i18n/en.lua"))(),
}

local i18nFiles = system.listFiles(GlobalPath .. "i18n")
for _, value in ipairs(i18nFiles) do
  if value == (locale .. ".lua") then
    i18nMap[locale] = assert(loadfile(GlobalPath .. "i18n/" .. locale .. ".lua"))()
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
