-- Pure math: where to draw the partner on the top screen.
local M = {}

M.defaults = {
  center_x = 128, -- screen pixel of your own character
  center_y = 104,
  tile_px = 16,   -- pixels per map tile near the player
  width = 256,
  height = 192,
  margin = 6,
  flip_y = false, -- set true if the partner moves the wrong way vertically
}

-- Returns x, y, on_screen. Off-screen positions are clamped to the screen edge.
function M.place(me, other, cfg)
  cfg = cfg or M.defaults
  local dx = (other.x - me.x) * cfg.tile_px
  local dy = (other.y - me.y) * cfg.tile_px
  if cfg.flip_y then dy = -dy end
  local x = cfg.center_x + dx
  local y = cfg.center_y + dy
  local m = cfg.margin
  local on = x >= m and x <= cfg.width - m and y >= m and y <= cfg.height - m
  if not on then
    x = math.max(m, math.min(cfg.width - m, x))
    y = math.max(m, math.min(cfg.height - m, y))
  end
  return x, y, on
end

function M.distance(me, other)
  return math.abs(other.x - me.x) + math.abs(other.y - me.y)
end

return M
