-- PokeMulti settings. Edit this file, then reload the script in DeSmuME.
return {
  names = { [1] = "Jogador1", [2] = "Jogador2" },

  -- Folder for the link files. nil = the "link" folder next to "lua".
  link_dir = nil,

  send_every = 4,      -- frames between two updates (4 = 15 per second)
  offline_after = 120, -- frames without updates before "offline" (60 = 1 second)
  toggle_key = "P",    -- key that shows or hides the overlay

  -- DeSmuME draws both screens in one area. Use 0 or -192 so the
  -- startup text shows on the top screen.
  top_screen_y = 0,

  marker = {
    center_x = 128, center_y = 104, tile_px = 16,
    width = 256, height = 192, margin = 6, flip_y = false,
  },
  color_fill = "#ff40a0a0",
  color_line = "white",
}
