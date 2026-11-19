-- RAM search engine, like the "unknown value" search of Cheat Engine.
-- read(addr) returns the value at addr. Pure Lua, so tests can use a fake RAM.
local M = {}
M.__index = M

function M.new(read, first, last, step)
  local self = setmetatable({}, M)
  self.read, self.first, self.last, self.step = read, first, last, step or 2
  self.addrs, self.vals = nil, nil
  return self
end

-- Take a full snapshot. Every address is a candidate.
function M:start()
  self.addrs, self.vals = {}, {}
  local n = 0
  for a = self.first, self.last, self.step do
    n = n + 1
    self.addrs[n] = a
    self.vals[n] = self.read(a)
  end
  return n
end

-- Keep candidates where test(old, new) is true. Returns the count left.
function M:filter(test)
  if not self.addrs then return 0 end
  local na, nv, n = {}, {}, 0
  local read, addrs, vals = self.read, self.addrs, self.vals
  for i = 1, #addrs do
    local v = read(addrs[i])
    if test(vals[i], v) then
      n = n + 1
      na[n] = addrs[i]
      nv[n] = v
    end
  end
  self.addrs, self.vals = na, nv
  return n
end

local function wrap16(d) return (d + 0x8000) % 0x10000 - 0x8000 end

M.tests = {
  plus1 = function(o, n) return wrap16(n - o) == 1 end,
  minus1 = function(o, n) return wrap16(n - o) == -1 end,
  same = function(o, n) return o == n end,
  changed = function(o, n) return o ~= n end,
}

function M:count() return self.addrs and #self.addrs or 0 end

function M:top(k)
  local out = {}
  for i = 1, math.min(k, self:count()) do
    out[i] = { addr = self.addrs[i], val = self.vals[i] }
  end
  return out
end

return M
