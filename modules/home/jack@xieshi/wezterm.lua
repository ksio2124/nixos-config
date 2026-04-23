local wezterm = require("wezterm")
local config = wezterm.config_builder()
config.color_scheme = "Tokyo Night"
config.window_background_opacity = 0.9
config.window_decorations = "TITLE | RESIZE"
-- https://github.com/wezterm/wezterm/issues/4962
config.enable_wayland = false
return config
