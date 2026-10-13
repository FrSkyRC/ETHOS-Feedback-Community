-- Caller sets PROTOCOL_NAME to "protocol_fbus" or "protocol_sport" before loading this file.
-- Both backends are loaded; UseProtocol selects the one the script will run.

local function loadChunk(name)
  local base = "config/" .. name
  local chunk = loadfile(base .. ".luac")
  if chunk == nil then
    chunk = assert(loadfile(base .. ".lua"), "Failed to load protocol: " .. name)
  end
  chunk()
end

local function capture()
  return {
    ProtocolReset = ProtocolReset,
    ProtocolPoll = ProtocolPoll,
    ProtocolRead = ProtocolRead,
    ProtocolSend = ProtocolSend,
    SportInterfaceBandrate = SportInterfaceBandrate,
    RollCalledInterval = RollCalledInterval,
  }
end

Protocols = {}
loadChunk("protocol_fbus")
Protocols.protocol_fbus = capture()
loadChunk("protocol_sport")
Protocols.protocol_sport = capture()

function UseProtocol(name)
  local protocol = Protocols[name]
  assert(protocol, "Unknown protocol: " .. tostring(name))
  ProtocolReset = protocol.ProtocolReset
  ProtocolPoll = protocol.ProtocolPoll
  ProtocolRead = protocol.ProtocolRead
  ProtocolSend = protocol.ProtocolSend
  SportInterfaceBandrate = protocol.SportInterfaceBandrate
  RollCalledInterval = protocol.RollCalledInterval
end

assert(PROTOCOL_NAME, "Set PROTOCOL_NAME before loading config")
UseProtocol(PROTOCOL_NAME)
assert(loadfile("config/ui.lua"))()
