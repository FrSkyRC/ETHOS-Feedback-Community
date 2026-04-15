local APP_TITLE = "VS Code Deploy Template"
local APP_MESSAGE = "Rename sampleapp and update .vscode/deploy.json before using this in a real project."

local function init()
    print(APP_TITLE)
    print(APP_MESSAGE)
end

return {
    init = init,
}
