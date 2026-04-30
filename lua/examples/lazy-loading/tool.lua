-- Loaded only when the "Lua Lazy Tool" system tool is opened.

local progress = nil
local progressValue = 0

local function closeProgress()
  if progress then
    progress:close()
    progress = nil
  end
  progressValue = 0
end

local function create()
  local data = {
    count = 3,
    enabled = true,
  }

  local line = form.addLine("Loaded module")
  form.addStaticText(line, nil, "tool.lua")

  line = form.addLine("Count")
  local countField = form.addNumberField(line, nil, 1, 10,
    function() return data.count end,
    function(value) data.count = value end)
  countField:default(3)

  line = form.addLine("Enabled")
  form.addBooleanField(line, nil,
    function() return data.enabled end,
    function(value) data.enabled = value end)

  line = form.addLine("Progress")
  form.addTextButton(line, nil, "Start",
    function()
      closeProgress()
      progress = form.openProgressDialog("Lazy tool", "Working from a lazy-loaded module...")
    end)

  return data
end

local function wakeup(data)
  if not progress then
    return
  end

  progressValue = progressValue + 2
  if progressValue >= 100 then
    closeProgress()
  else
    progress:value(progressValue)
  end
end

local function event(data, category, value, x, y)
  print("Lazy tool event:", category, value, x, y)
  return false
end

local function close(data)
  closeProgress()
end

return {
  create = create,
  wakeup = wakeup,
  event = event,
  close = close,
}
