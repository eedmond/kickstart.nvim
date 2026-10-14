return {
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    flavour = 'mocha',
    priority = 1000,
    -- Use the terminal/tmux pane background instead of painting Catppuccin's own.
    -- float.transparent extends this to floating windows (Telescope, LSP hovers, etc.).
    opts = { transparent_background = true, float = { transparent = true } },
  },
}
