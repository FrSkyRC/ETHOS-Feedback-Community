local APP_TITLE = "@i18n(app.title)@"
local APP_MESSAGE = "@i18n(app.message)@"

local function init()
    print(APP_TITLE)
    print(APP_MESSAGE)
end

return {
    init = init,
}
