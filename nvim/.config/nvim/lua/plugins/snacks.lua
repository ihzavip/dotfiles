return {
  "folke/snacks.nvim",
  opts = {
    -- Keep static indent guides but disable the scroll animation: redrawing the
    -- animated guides on every j/k move lags on the 1440p external monitor.
    indent = {
      enabled = false,
      animate = { enabled = false },
    },
    picker = {
      sources = {
        todo_comments = {
          args = { "--glob", "!**/vendored/**", "--glob", "!**/vendor/**" },
        },
      },
      win = {
        input = {
          keys = {
            ["<c-u>"] = { "preview_scroll_up", mode = { "i", "n" } },
            ["<c-d>"] = { "preview_scroll_down", mode = { "i", "n" } },
          },
        },
        list = {
          keys = {
            ["<c-u>"] = "preview_scroll_up",
            ["<c-d>"] = "preview_scroll_down",
          },
        },
      },
    },
  },
}
