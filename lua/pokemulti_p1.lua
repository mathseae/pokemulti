-- Load this file in the DeSmuME window of player 1.
POKEMULTI_PLAYER = 1
local dir = debug.getinfo(1, "S").source:gsub("^@", ""):match("^(.*[/\\])") or "./"
dofile(dir .. "pokemulti.lua")
