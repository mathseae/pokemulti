-- PokeMulti RAM scanner. Finds the addresses of map, x and y.
-- Load this file in DeSmuME, alone (not with pokemulti_p1.lua).
-- Keys (number row):
--   1 = new scan for the current field
--   2 = value went up by 1     3 = value went down by 1
--   4 = value did not change   5 = value changed
--   6 = next field (map -> x -> y -> dir)
--   7 = accept the first candidate for the current field
--   0 = save accepted fields in addresses_local.lua
local DIR = debug.getinfo(1, "S").source:gsub("^@", ""):match("^(.*[/\\])") or "./"
package.path = DIR .. "?.lua;" .. package.path
local scan_mod = require("coop.scan")
local addresses = require("coop.addresses")
local config = require("config")

local FIRST, LAST = 0x02000000, 0x023FFFFE -- 4 MB main RAM
local FIELDS = { "map", "x", "y", "dir" }
local field_i = 1
local found = {}
local msg = "Pressione 1 para comecar"

local function game_code()
  local s = ""
  for i = 0, 3 do s = s .. string.char(memory.readbyte(addresses.HEADER_GAME_CODE + i)) end
  return s
end
local GAME = game_code()

local scan = scan_mod.new(memory.readword, FIRST, LAST, 2)

local function save()
  local path = DIR .. "addresses_local.lua"
  local old = {}
  local ok, t = pcall(dofile, path)
  if ok and type(t) == "table" then old = t end
  old[GAME] = old[GAME] or {}
  for k, v in pairs(found) do old[GAME][k] = v end
  local f = assert(io.open(path, "w"))
  f:write("-- Written by ramscan.lua. Addresses found on this machine.\nreturn {\n")
  for game, tbl in pairs(old) do
    f:write(string.format("  [%q] = {\n", game))
    for k, v in pairs(tbl) do
      f:write(string.format("    %s = { addr = 0x%08X, size = %d },\n", k, v.addr, v.size or 2))
    end
    f:write("  },\n")
  end
  f:write("}\n")
  f:close()
  return path
end

local actions = {
  ["1"] = function() local n = scan:start(); msg = "Nova busca: " .. n .. " candidatos" end,
  ["2"] = function() msg = "+1: " .. scan:filter(scan_mod.tests.plus1) end,
  ["3"] = function() msg = "-1: " .. scan:filter(scan_mod.tests.minus1) end,
  ["4"] = function() msg = "igual: " .. scan:filter(scan_mod.tests.same) end,
  ["5"] = function() msg = "mudou: " .. scan:filter(scan_mod.tests.changed) end,
  ["6"] = function()
    field_i = field_i % #FIELDS + 1
    msg = "Campo: " .. FIELDS[field_i] .. ". Pressione 1"
  end,
  ["7"] = function()
    local c = scan:top(1)[1]
    if c then
      found[FIELDS[field_i]] = { addr = c.addr, size = 2 }
      msg = string.format("%s = 0x%08X", FIELDS[field_i], c.addr)
      print("Aceito: " .. msg)
    else
      msg = "Sem candidatos"
    end
  end,
  ["0"] = function() msg = "Salvo em " .. save(); print(msg) end,
}

local was = {}
emu.registerafter(function()
  local keys = input.get()
  for k, fn in pairs(actions) do
    if keys[k] and not was[k] then fn() end
    was[k] = keys[k]
  end
end)

local Y0 = config.top_screen_y
gui.register(function()
  gui.text(2, Y0 + 2, "RAMSCAN " .. GAME .. "  campo: " .. FIELDS[field_i], "white")
  gui.text(2, Y0 + 12, msg, "yellow")
  local y = 24
  for _, c in ipairs(scan:top(8)) do
    gui.text(2, Y0 + y, string.format("%08X = %d", c.addr, c.val), "white")
    y = y + 10
  end
  local fy = 120
  for k, v in pairs(found) do
    gui.text(2, Y0 + fy, string.format("OK %s %08X = %d", k, v.addr, memory.readword(v.addr)), "green")
    fy = fy + 10
  end
end)

print("RAMSCAN carregado. Jogo " .. GAME .. ". Veja docs/encontrar-enderecos.md")
