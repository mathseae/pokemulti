-- Load this file in the DeSmuME window of player 2.
POKEMULTI_PLAYER = 2
local dir = debug.getinfo(1, "S").source:gsub("^@", ""):match("^(.*[/\\])") or "./"
dofile(dir .. "pokemulti.lua")
