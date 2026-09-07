PROTOCOL_FBUS = "protocol_fbus"

function LoadProtocol(name)
  local base = "config/" .. name
  local chunk = loadfile(base .. ".luac")
  if chunk == nil then
    chunk = assert(loadfile(base .. ".lua"), "Failed to load protocol: " .. name)
  end
  chunk()
end

LoadProtocol(PROTOCOL_FBUS)
assert(loadfile("config/ui.lua"))()
