-- Lua Layout example

local function init()
  system.registerLayout({key="XL+3", widgets={
    {x=8, y=95, w=784, h=248},
    {x=8, y=351, w=256, h=56},
    {x=272, y=351, w=256, h=56},
    {x=536, y=351, w=256, h=56}
  }})
end

return {init=init}
