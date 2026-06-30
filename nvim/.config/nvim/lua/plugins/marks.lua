local function bookmark()
  for i = 0, 25 do
    local letter = string.char(string.byte("A") + i)
    local pos = vim.fn.getpos("'" .. letter)
    if pos[2] == 0 then
      vim.cmd("mark " .. letter)
      vim.notify("Mark '" .. letter .. "' set")
      return
    end
  end
  vim.notify("All marks A-Z are used", vim.log.levels.WARN)
end

local function next_mark()
  local lnum = vim.fn.line(".")
  local marks = {}
  for _, base in ipairs({ string.byte("a"), string.byte("A") }) do
    for i = 0, 25 do
      local letter = string.char(base + i)
      local pos = vim.fn.getpos("'" .. letter)
      if pos[2] > 0 then
        table.insert(marks, pos[2])
      end
    end
  end
  if #marks == 0 then
    vim.notify("No marks in buffer", vim.log.levels.WARN)
    return
  end
  table.sort(marks)
  for _, m in ipairs(marks) do
    if m > lnum then
      vim.cmd(tostring(m))
      return
    end
  end
  vim.cmd(tostring(marks[1]))
end

local function delete_line_marks()
  local lnum = vim.fn.line(".")
  local deleted = {}
  for _, base in ipairs({ string.byte("a"), string.byte("A") }) do
    for i = 0, 25 do
      local letter = string.char(base + i)
      local pos = vim.fn.getpos("'" .. letter)
      if pos[2] == lnum then
        vim.cmd("delmarks " .. letter)
        table.insert(deleted, letter)
      end
    end
  end
  if #deleted > 0 then
    vim.notify("Deleted mark(s): " .. table.concat(deleted, ", "))
  else
    vim.notify("No mark on this line", vim.log.levels.WARN)
  end
end

vim.keymap.set("n", "<leader>m", "<nop>", { desc = "+marks" })
vim.keymap.set("n", "<leader>ml", function()
  Snacks.picker.marks({
    transform = function(item)
      return item.label:match("^[a-zA-Z]$") and item or false
    end,
  })
end, { desc = "Marks: list" })

vim.keymap.set("n", "<leader>mm", bookmark, { desc = "Marks: bookmark (A-Z)" })
vim.keymap.set("n", "<leader>mn", next_mark, { desc = "Marks: next in buffer" })
vim.keymap.set("n", "<leader>md", delete_line_marks, { desc = "Marks: delete on line" })
vim.keymap.set("n", "<leader>ma", "<cmd>delmarks! | delmarks ABCDEFGHIJKLMNOPQRSTUVWXYZ | delmarks 0123456789<CR>", { desc = "Marks: delete all" })

return {}
