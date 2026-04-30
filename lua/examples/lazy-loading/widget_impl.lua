-- Loaded only when the "Lua Lazy Widget" is created, painted, configured, etc.

local function resetCachedValue(widget)
  widget.value = nil
  widget.text = "--"
end

local function create()
  return {
    source = nil,
    value = nil,
    text = "--",
  }
end

local function paint(widget)
  local w, h = lcd.getWindowSize()
  local text = widget.text or "--"

  lcd.font(FONT_STD)
  local textW, textH = lcd.getTextSize(text)
  lcd.drawText((w - textW) / 2, (h - textH) / 2, text)
end

local function wakeup(widget)
  local source = widget.source
  local value = source and source:value() or nil

  if widget.value ~= value then
    widget.value = value
    widget.text = source and source:stringValue() or "--"
    lcd.invalidate()
  end
end

local function configure(widget)
  local line = form.addLine("Source")
  form.addSourceField(line, nil,
    function() return widget.source end,
    function(value)
      widget.source = value
      resetCachedValue(widget)
      lcd.invalidate()
    end)
end

local function read(widget)
  widget.source = storage.read("source")
  resetCachedValue(widget)
end

local function write(widget)
  storage.write("source", widget.source)
end

local function close(widget)
  resetCachedValue(widget)
end

return {
  create = create,
  paint = paint,
  wakeup = wakeup,
  configure = configure,
  read = read,
  write = write,
  close = close,
}
