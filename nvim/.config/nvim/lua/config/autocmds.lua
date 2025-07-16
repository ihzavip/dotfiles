-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
--
--

vim.keymap.set("v", "<leader>ob", function()
  -- Yank visual selection to register v
  vim.cmd('normal! "vy')

  local text = vim.fn.getreg("v"):gsub("\n", " ")
  text = vim.fn.trim(text)

  if text == "" then
    vim.notify("Selection is empty", vim.log.levels.WARN)
    return
  end

  -- Check if it's a URL
  local is_url = text:match("^https?://") or text:match("^www%.")
  local target

  if is_url then
    -- Ensure full URL (in case of www only)
    if text:match("^www%.") then
      text = "https://" .. text
    end
    target = text
  else
    -- Encode as Google search
    local encoded = text:gsub(" ", "+")
    target = "https://www.google.com/search?q=" .. encoded
  end

  vim.fn.jobstart({ "xdg-open", target }, { detach = true })
end, { desc = "Smart open URL or Google search", silent = true })
