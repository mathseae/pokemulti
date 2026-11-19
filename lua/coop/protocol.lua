-- Wire format shared by the Lua scripts and the Python relay.
-- One line per state:  PM1|seq|game|map|x|y|dir|name|END
local M = {}

M.VERSION = "PM1"
M.FIELDS = { "seq", "game", "map", "x", "y", "dir", "name" }
local NUMERIC = { seq = true, map = true, x = true, y = true, dir = true }

local function clean(s)
  s = tostring(s or "")
  s = s:gsub("[|\r\n]", "")
  return s:sub(1, 16)
end

function M.encode(st)
  local parts = { M.VERSION }
  for _, k in ipairs(M.FIELDS) do
    local v = st[k]
    if NUMERIC[k] then
      v = math.floor(tonumber(v) or -1)
    else
      v = clean(v)
    end
    parts[#parts + 1] = tostring(v)
  end
  parts[#parts + 1] = "END"
  return table.concat(parts, "|")
end

-- Returns a table, or nil and a reason.
function M.decode(line)
  if type(line) ~= "string" then return nil, "no data" end
  line = line:gsub("[\r\n]+$", "")
  local parts = {}
  for p in (line .. "|"):gmatch("([^|]*)|") do parts[#parts + 1] = p end
  if parts[1] ~= M.VERSION then return nil, "bad version" end
  if #parts ~= #M.FIELDS + 2 or parts[#parts] ~= "END" then
    return nil, "incomplete line"
  end
  local st = {}
  for i, k in ipairs(M.FIELDS) do
    local v = parts[i + 1]
    if NUMERIC[k] then
      v = tonumber(v)
      if not v then return nil, "bad number in " .. k end
    end
    st[k] = v
  end
  return st
end

return M
