return {
  {
    "LazyVim/LazyVim",
    init = function()
      vim.api.nvim_create_autocmd("BufEnter", {
        callback = function()
          vim.opt.formatoptions:remove({ "c", "r", "o" })
        end,
      })
    end,
  },
}
