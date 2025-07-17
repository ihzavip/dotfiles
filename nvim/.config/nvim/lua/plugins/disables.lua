return {
  -- Disable all mini.animate animations
  {
    "echasnovski/mini.animate",
    opts = {
      scroll = { enable = false },
      cursor = { enable = false },
      resize = { enable = false },
      open = { enable = false },
      close = { enable = false },
    },
  },

  -- Snacks: turn off animation globally
  {
    "folke/snacks.nvim",
    opts = {
      animate = { enabled = false },
    },
  },
}
