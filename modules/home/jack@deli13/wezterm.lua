local wezterm = require("wezterm")
local config = wezterm.config_builder()
config.color_scheme = "Tokyo Night"
config.window_background_opacity = 0.9
config.window_decorations = "TITLE | RESIZE"
config.enable_wayland = true
return config
