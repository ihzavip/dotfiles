-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Transparent explorer and float backgrounds
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = function()
    local groups = {
      "Normal",
      "NormalNC",
      "NormalFloat",
      "FloatBorder",
      "SnacksPickerList",
      "SnacksPickerPreview",
      "SnacksPickerInput",
      "SnacksNormal",
      "SnacksDashboard",
      "SnacksExplorer",
      "NeoTreeNormal",
      "NeoTreeNormalNC",
    }
    for _, group in ipairs(groups) do
      vim.api.nvim_set_hl(0, group, { bg = "NONE" })
    end

    -- Trouble symbols active item
    vim.api.nvim_set_hl(0, "TroubleCurrentItem", { bg = "#3a2e00", fg = "#f0c040", bold = true })
    vim.api.nvim_set_hl(0, "TroubleNormalNC", { bg = "NONE" })
    vim.api.nvim_set_hl(0, "TroubleNormal", { bg = "NONE" })
  end,
})

-- Auto-open Trouble symbols on LspAttach
vim.api.nvim_create_autocmd("LspAttach", {
  once = true,
  callback = function()
    vim.cmd("Trouble symbols open")
  end,
})

-- Disable comment continuation when using o/O or Enter
vim.api.nvim_create_autocmd("FileType", {
  callback = function()
    vim.opt_local.formatoptions:remove({ "o", "r" })
  end,
})

-- Autoformat setting
local set_autoformat = function(pattern, bool_val)
  vim.api.nvim_create_autocmd({ "FileType" }, {
    pattern = pattern,
    callback = function()
      vim.b.autoformat = bool_val
    end,
  })
end

set_autoformat({ "c" }, false)
set_autoformat({ "yaml" }, false)

-- Disable mouse in terminal mode so selection doesn't bleed into Neovim buffers
vim.api.nvim_create_autocmd("TermEnter", {
  callback = function()
    vim.opt.mouse = ""
  end,
})
vim.api.nvim_create_autocmd("TermLeave", {
  callback = function()
    vim.opt.mouse = "a"
  end,
})
