-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("n", "<leader>sf", function()
  Snacks.picker.grep_word({ dirs = { vim.fn.expand("%:p") } })
end, { desc = "Search word in current file" })

vim.keymap.set("v", "<leader>sf", function()
  local s = vim.fn.getpos("'<")
  local e = vim.fn.getpos("'>")
  local lines = vim.fn.getregion(s, e, { type = "v" })
  local text = table.concat(lines, "\n")
  Snacks.picker.grep({ search = text, dirs = { vim.fn.expand("%:p") } })
end, { desc = "Search selection in current file" })

vim.keymap.set("v", "<leader>a", function()
  local s = vim.fn.line("v")
  local e = vim.fn.line(".")
  if s > e then s, e = e, s end
  local path = vim.fn.expand("%:.")
  local ref = "@" .. path .. "#L" .. s .. (s ~= e and ("-L" .. e) or "")
  vim.fn.setreg("+", ref)
  vim.notify("Copied: " .. ref)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
end, { desc = "Copy file:line ref" })
