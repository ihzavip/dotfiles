return {
  {
    "Bekaboo/dropbar.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    keys = {
      {
        "<leader>uB",
        function()
          vim.o.winbar = vim.o.winbar == "" and "%{%v:lua.dropbar()%}" or ""
        end,
        desc = "Toggle dropbar",
      },
    },
    opts = function()
      local sources = require("dropbar.sources")
      return {
        bar = {
          sources = function(buf, _)
            if vim.bo[buf].ft == "markdown" then
              return { sources.path, sources.markdown }
            end
            return {
              sources.path,
              sources.lsp,
              sources.treesitter,
            }
          end,
        },
      }
    end,
  },
}
