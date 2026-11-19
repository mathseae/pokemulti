-- RAM address tables, one per game code (from the cartridge header).
-- Each field: { addr = <number>, size = 1|2|4, signed = bool }
-- Pokemon Black/White addresses are NOT verified yet. Find them with ramscan.lua.
-- Results saved by ramscan.lua in addresses_local.lua override this table.
local M = {}

M.HEADER_GAME_CODE = 0x027FFE0C -- ARM9 copy of the cartridge header, 4 ASCII bytes

M.games = {
  IRBO = { title = "Pokemon Black (USA/EU)" },
  IRAO = { title = "Pokemon White (USA/EU)" },
  IRBJ = { title = "Pocket Monsters Black (JPN)" },
  IRAJ = { title = "Pocket Monsters White (JPN)" },
  IRBP = { title = "Pokemon Black (EUR)" },
  IRAP = { title = "Pokemon White (EUR)" },
  IRBF = { title = "Pokemon Noire (FRA)" },
  IRBD = { title = "Pokemon Schwarze (GER)" },
  IRBI = { title = "Pokemon Nero (ITA)" },
  IRBS = { title = "Pokemon Negra (ESP)" },
}

M.REQUIRED = { "map", "x", "y" }
M.OPTIONAL = { "dir" }

function M.merge(base, override)
  local out = {}
  for k, v in pairs(base or {}) do out[k] = v end
  for k, v in pairs(override or {}) do out[k] = v end
  return out
end

function M.missing(tbl)
  local miss = {}
  for _, k in ipairs(M.REQUIRED) do
    if not (tbl[k] and tbl[k].addr) then miss[#miss + 1] = k end
  end
  return miss
end

return M
