-- Lua Snake game

local translations = {en="Lua Snake", fr="Serpent Lua"}

local function name(widget)
    local locale = system.getLocale()
    return translations[locale] or translations["en"]
end

local wCell = 12
local xMax
local yMax
local game_map = {}
local Head
local Tail
local highscore = 0
local size = 3
local Food = {x=false, y=false}
local direction = "right"
local score = 0

local function create_food()
  Food.x, Food.y = math.random(xMax - 1), math.random(yMax - 1)
  while game_map[Food.x][Food.y] do
    Food.x, Food.y = math.random(xMax - 1), math.random(yMax - 1)
  end
  game_map[Food.x][Food.y] = "food"
end

local function eat_food()
  game_map[Head.x][Head.y] = nil
  create_food()
  score = score + 1
end

local function check_collision()
  if Head.x < 0 or Head.x > xMax then
    return true
  elseif Head.y < 0 or Head.y > yMax then
    return true
  elseif ((game_map[Head.x][Head.y]) and (game_map[Head.x][Head.y] ~= "food")) then
    return true
  end
  return false
end

local function move()
  if game_map[Tail.x][Tail.y] == "right" then
    Tail.dx = 1
    Tail.dy = 0
  elseif game_map[Tail.x][Tail.y] == "left" then
    Tail.dx = -1
    Tail.dy = 0
  elseif game_map[Tail.x][Tail.y] == "up" then
    Tail.dx = 0
    Tail.dy = -1
  elseif game_map[Tail.x][Tail.y] == "down" then
    Tail.dx = 0
    Tail.dy = 1
  end

  game_map[Head.x][Head.y] = direction
  Head.x = Head.x + Head.dx
  Head.y = Head.y + Head.dy

  lcd.invalidate()

  if Head.x < 0 or Head.x > xMax or Head.y < 0 or Head.y > yMax then
    print("Game over!")
    system.exit()
  elseif game_map[Head.x][Head.y] == "food" then
    eat_food()
  else
    game_map[Tail.x][Tail.y] = nil
    Tail.x = Tail.x + Tail.dx
    Tail.y = Tail.y + Tail.dy
  end
end

local function create()
  local w, h = lcd.getWindowSize()
  xMax = math.floor(w / wCell)
  yMax = math.floor(h / wCell)

  food = false
  size = 3
  score = 0
  Head = {x=3, y=1, dx=1, dy=0}
  Tail = {x=1, y=1, dx=1, dy=0}
  direction = "right"

  for i = 0, xMax, 1 do
    game_map[i] = {}
  end

  for i = 0, size - 1, 1 do
    game_map[Tail.x + (i * Tail.dx)][Tail.y + (i * Tail.dy)] = direction
  end

  create_food()
end

local function wakeup()
  move()
end

local function event(widget, category, value, x, y)
  print("Event received:", category, value, x, y, KEY_RIGHT_FIRST)

  local dir = direction
  local result = false

  if category == EVT_KEY then
    result = true
    if value == KEY_RIGHT_FIRST and direction ~= "left" then
      dir = "right"
      Head.dx = 1
      Head.dy = 0
    elseif value == KEY_LEFT_FIRST and direction ~= "right" then
      dir = "left"
      Head.dx = -1
      Head.dy = 0
    elseif value == KEY_UP_FIRST and direction ~= "down" then
      dir = "up"
      Head.dx = 0
      Head.dy = -1
    elseif value == KEY_DOWN_FIRST and direction ~= "up" then
      dir = "down"
      Head.dx = 0
      Head.dy = 1
    end
  elseif category == EVT_CLOSE then
    print("No, you will play until the end!")
    result = true
  end

  direction = dir

  return result
end

local function paint()
  lcd.color(lcd.RGB(40, 40, 40))

  for x = 0, xMax, 1 do
    lcd.drawFilledRectangle(x * wCell, 0, 1, yMax * wCell)
  end

  for y = 0, yMax, 1 do
    lcd.drawFilledRectangle(0, y * wCell, xMax * wCell, 1)
  end

  for x = 0, xMax, 1 do
    for y = 0, yMax, 1 do
      local cell = game_map[x][y]
      if cell ~= nil then
        if cell == "food" then
          lcd.color(lcd.RGB(79, 195, 247))
        else
          lcd.color(lcd.RGB(255, 255, 255))
        end
        lcd.drawFilledRectangle(x * wCell + 1, y * wCell + 1, wCell - 1, wCell - 1)
      end
    end
  end
end

local icon = lcd.loadMask("snake.png")

local function init()
  system.registerSystemTool({name=name, icon=icon, create=create, wakeup=wakeup, event=event, paint=paint})
end

return {init=init}

