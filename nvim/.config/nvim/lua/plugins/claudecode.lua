return {}

--[[ claudecode.nvim (disabled)
return {
  "coder/claudecode.nvim",
  opts = {
    terminal = {
      provider = "snacks",
      snacks_win_opts = {
        position = "float",
        width = 0.9,
        height = 0.9,
        border = "rounded",
        title = " Claude Code ",
        title_pos = "center",
      },
    },
  },
  config = function(_, opts)
    require("claudecode").setup(opts)
    local ok, wk = pcall(require, "which-key")
    if ok then wk.add({ { "<leader>a", group = "AI/Claude Code" } }) end
    vim.keymap.set("t", "<C-q>", "<cmd>close<cr>", { desc = "Close Claude float" })
    vim.keymap.set({ "n", "i" }, "<C-q>", "<cmd>ClaudeCode<cr>", { desc = "Toggle Claude float" })
  end,
  keys = {
    { "<leader>ac", "<cmd>ClaudeCode<cr>",        desc = "Toggle Claude" },
    { "<leader>af", "<cmd>ClaudeCodeFocus<cr>",   desc = "Focus Claude" },
    { "<leader>as", "<cmd>ClaudeCodeSend<cr>",    mode = "v", desc = "Send to Claude" },
    { "<leader>as", "<cmd>ClaudeCodeTreeAdd<cr>", desc = "Add file", ft = { "NvimTree", "neo-tree", "oil", "minifiles", "netrw" } },
    { "<leader>ar", function() vim.fn.system("tmux new-window -a 'claude --resume'") end, desc = "Resume Claude in tmux tab" },
    { "<leader>aC", "<cmd>ClaudeCode --continue<cr>",   desc = "Continue Claude" },
    { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>",   desc = "Select Claude model" },
    { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>",         desc = "Add current buffer" },
    { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>",    desc = "Accept diff" },
    { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>",      desc = "Deny diff" },
  },
}
]]