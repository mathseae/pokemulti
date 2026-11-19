-- Fake DeSmuME Lua API. Usage:
--   lua5.1 fake_desmume.lua <lua dir> <player> <frames> <map> <x> <y> <log>
-- Runs the player script for N frames on a fake RAM and logs gui calls.
local dir, player, frames, map, x, y, logpath = unpack(arg)
frames = tonumber(frames)

local RAM = {}
local code = "IRBO"
for i = 1, 4 do RAM[0x027FFE0C + i - 1] = code:byte(i) end
local A_MAP, A_X, A_Y = 0x02200000, 0x02200010, 0x02200014
RAM[A_MAP], RAM[A_X], RAM[A_Y] = tonumber(map), tonumber(x), tonumber(y)

memory = {
  readbyte = function(a) return RAM[a] or 0 end,
  readword = function(a) return RAM[a] or 0 end,
  readdword = function(a) return RAM[a] or 0 end,
}
memory.readbytesigned, memory.readwordsigned, memory.readdwordsigned =
  memory.readbyte, memory.readword, memory.readdword

local after, draw
emu = { registerafter = function(f) after = f end }
local log = assert(io.open(logpath, "w"))
gui = {
  register = function(f) draw = f end,
  text = function(px, py, s) log:write("text|", px, "|", py, "|", s, "\n") end,
  box = function(x1, y1, x2, y2) log:write("box|", x1, "|", y1, "|", x2, "|", y2, "\n") end,
}
input = { get = function() return {} end }
print = function() end

POKEMULTI_PLAYER = tonumber(player)
dofile(dir .. "pokemulti.lua")
for _ = 1, frames do after(); draw() end
log:close()
