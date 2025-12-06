local wezterm = require 'wezterm'

local config = {
  enable_wayland = true,

  scrollback_lines = 100000,

  color_scheme = "Molokai", -- or "Catppuccin Mocha", "Tokyo Night"
  font = wezterm.font_with_fallback {
    "IosevkaTerm Nerd Font",
    "JetBrains Mono",
    "FiraCode Nerd Font",
    "Iosevka Term",
  },
  font_size = 11.0,
  window_background_opacity = 0.95,
  text_background_opacity = 1.0,
  adjust_window_size_when_changing_font_size = false,
  window_decorations = "NONE",
  hide_tab_bar_if_only_one_tab = true,
  tab_bar_at_bottom = true,
  use_fancy_tab_bar = false,
  enable_scroll_bar = true,
  tab_max_width = 20,

  leader = { key = "a", mods = "CTRL", timeout_milliseconds = 2000 },
  keys = {
    { key = "b", mods = "LEADER", action = wezterm.action.SplitHorizontal { domain = "CurrentPaneDomain" } },
    { key = "v", mods = "LEADER",       action = wezterm.action.SplitVertical { domain = "CurrentPaneDomain" } },

    { key = "u", mods = "LEADER", action = wezterm.action.PaneSelect },
    { key = "h", mods = "LEADER", action = wezterm.action.ActivatePaneDirection "Left" },
    { key = "l", mods = "LEADER", action = wezterm.action.ActivatePaneDirection "Right" },
    { key = "k", mods = "LEADER", action = wezterm.action.ActivatePaneDirection "Up" },
    { key = "j", mods = "LEADER", action = wezterm.action.ActivatePaneDirection "Down" },

    { key = "u", mods = "ALT", action = wezterm.action.PaneSelect },
    { key = "h", mods = "ALT", action = wezterm.action.ActivatePaneDirection "Left" },
    { key = "l", mods = "ALT", action = wezterm.action.ActivatePaneDirection "Right" },
    { key = "k", mods = "ALT", action = wezterm.action.ActivatePaneDirection "Up" },
    { key = "j", mods = "ALT", action = wezterm.action.ActivatePaneDirection "Down" },

    { key = "c", mods = "LEADER", action = wezterm.action.SpawnTab "CurrentPaneDomain" },
    { key = "n", mods = "LEADER", action = wezterm.action.ActivateTabRelative(1) },
    { key = "p", mods = "LEADER", action = wezterm.action.ActivateTabRelative(-1) },
    { key = "x", mods = "LEADER", action = wezterm.action.CloseCurrentPane { confirm = true } },

    { key = "r", mods = "LEADER", action = wezterm.action.PromptInputLine {
        description = "Rename tab",
        action = wezterm.action_callback(function(window, pane, line)
          if line then window:active_tab():set_title(line) end
        end),
      },
    },

    { key = "Space", mods = "LEADER", action = wezterm.action.ShowLauncher },
  },
}

for i = 1, 9 do
  table.insert(config.keys, { key = tostring(i), mods = "LEADER", action = wezterm.action.ActivateTab(i - 1) })
end

return config
