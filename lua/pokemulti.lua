-- PokeMulti: co-op presence for Pokemon Black/White in DeSmuME.
-- Do not load this file directly. Load pokemulti_p1.lua or pokemulti_p2.lua.

local function script_dir()
  local src = debug.getinfo(1, "S").source
  src = src:gsub("^@", "")
  return src:match("^(.*[/\\])") or "./"
end

local DIR = script_dir()
package.path = DIR .. "?.lua;" .. package.path

local config = require("config")
local protocol = require("coop.protocol")
local link_mod = require("coop.link")
local addresses = require("coop.addresses")
local marker = require("coop.marker")

local ME = POKEMULTI_PLAYER or 1
local PARTNER = (ME == 1) and 2 or 1
local LINK_DIR = config.link_dir or (DIR .. "../link/")

-- Read the game code from the cartridge header copy in RAM.
local function game_code()
  local s = ""
  for i = 0, 3 do
    local b = memory.readbyte(addresses.HEADER_GAME_CODE + i)
    if b < 32 or b > 126 then return "????" end
    s = s .. string.char(b)
  end
  return s
end

local function load_local_addresses()
  local ok, tbl = pcall(dofile, DIR .. "addresses_local.lua")
  if ok and type(tbl) == "table" then return tbl end
  return {}
end

local GAME = game_code()
local ADDR = addresses.merge(addresses.games[GAME], load_local_addresses()[GAME])
local MISSING = addresses.missing(ADDR)

local function read_field(f)
  if not f or not f.addr then return -1 end
  local size = f.size or 2
  if size == 1 then
    return f.signed and memory.readbytesigned(f.addr) or memory.readbyte(f.addr)
  elseif size == 4 then
    return f.signed and memory.readdwordsigned(f.addr) or memory.readdword(f.addr)
  end
  return f.signed and memory.readwordsigned(f.addr) or memory.readword(f.addr)
end

local link = link_mod.new(LINK_DIR, ME, PARTNER)
local seq = 0
local frame = 0
local overlay_on = true
local key_was_down = false
local me_state = nil

local function sample()
  return {
    seq = seq,
    game = GAME,
    map = read_field(ADDR.map),
    x = read_field(ADDR.x),
    y = read_field(ADDR.y),
    dir = read_field(ADDR.dir),
    name = config.names[ME] or ("P" .. ME),
  }
end

emu.registerafter(function()
  frame = frame + 1
  local keys = input.get()
  local down = keys[config.toggle_key] and true or false
  if down and not key_was_down then overlay_on = not overlay_on end
  key_was_down = down

  if #MISSING == 0 and frame % config.send_every == 0 then
    seq = seq + 1
    me_state = sample()
    link:write(me_state)
  end
end)

local Y0 = config.top_screen_y
local function text(x, y, s, color) gui.text(x, Y0 + y, s, color) end

gui.register(function()
  if frame < 300 then
    text(2, 2, "PokeMulti P" .. ME .. "  jogo: " .. GAME, "white")
    -- Calibration hint: this label must be on the TOP screen.
    text(2, 12, "Se este texto esta na tela de baixo, ajuste top_screen_y", "yellow")
  end
  if #MISSING > 0 then
    text(2, 24, "Faltam enderecos: " .. table.concat(MISSING, ", "), "red")
    text(2, 34, "Rode ramscan.lua (veja README)", "red")
    return
  end
  if not overlay_on or not me_state then return end

  local p, age = link:read()
  if not p or age > config.offline_after then
    text(2, 182, "Parceiro offline", "gray")
    return
  end
  if p.game ~= GAME then
    text(2, 182, "Parceiro usa outro jogo: " .. p.game, "red")
    return
  end
  if p.map ~= me_state.map then
    text(2, 182, p.name .. " em outro mapa (" .. p.map .. ")", "orange")
    return
  end

  local x, y, on = marker.place(me_state, p, config.marker)
  local r = on and 7 or 4
  gui.box(x - r, Y0 + y - r, x + r, Y0 + y + r, config.color_fill, config.color_line)
  text(x - 8, y - r - 10, p.name, "white")
  if not on then
    text(2, 182, p.name .. ": " .. marker.distance(me_state, p) .. " passos", "white")
  end
end)

print("PokeMulti carregado. Jogador " .. ME .. ", jogo " .. GAME .. ", link " .. LINK_DIR)
if #MISSING > 0 then
  print("Enderecos de RAM faltando: " .. table.concat(MISSING, ", ") .. ". Rode ramscan.lua.")
end
