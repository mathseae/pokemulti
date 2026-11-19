-- File link between two emulator windows.
-- Each player writes its own file and reads the partner's file.
-- On one PC both windows share the folder. Over a network, relay.py copies the files.
local protocol = require("coop.protocol")

local M = {}
M.__index = M

function M.new(dir, me, partner)
  local self = setmetatable({}, M)
  self.out_path = dir .. "p" .. me .. ".txt"
  self.in_path = dir .. "p" .. partner .. ".txt"
  self.last_seq = nil
  self.age = math.huge -- frames since the partner's seq changed
  self.partner = nil
  return self
end

function M:write(st)
  local f = io.open(self.out_path, "w")
  if not f then return false end
  f:write(protocol.encode(st), "\n")
  f:close()
  return true
end

-- Call once per frame. Returns the partner state (or nil) and its age in frames.
function M:read()
  self.age = self.age + 1
  local f = io.open(self.in_path, "r")
  if f then
    local line = f:read("*l")
    f:close()
    local st = protocol.decode(line)
    if st then
      if st.seq ~= self.last_seq then
        self.last_seq = st.seq
        self.age = 0
      end
      self.partner = st
    end
  end
  return self.partner, self.age
end

return M
