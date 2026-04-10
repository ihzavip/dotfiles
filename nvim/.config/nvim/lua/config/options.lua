-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.wrap = true
vim.opt.linebreak = true -- don’t break words
vim.opt.breakindent = true -- keep indentation

vim.g.telescope_ignore_patterns = {
  "node_modules",
  ".git/",
  "dist/",
  "build/",
  "target/",
}
