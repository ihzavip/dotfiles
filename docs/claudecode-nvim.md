# claudecode.nvim

Source: https://github.com/coder/claudecode.nvim

Pure Lua Neovim integration for Claude Code. Reverse-engineered the official extension protocol — WebSocket-based MCP, zero external dependencies.

## Requirements

- Neovim >= 0.8.0
- Claude Code CLI installed
- `folke/snacks.nvim` for terminal support

## Commands

| Command | Purpose |
|---------|---------|
| `:ClaudeCode` | Toggle Claude terminal window |
| `:ClaudeCodeFocus` | Smart focus/toggle terminal |
| `:ClaudeCodeSelectModel` | Select model |
| `:ClaudeCodeSend` | Send visual selection to Claude |
| `:ClaudeCodeAdd <file> [start] [end]` | Add file to context (optional line range) |
| `:ClaudeCodeDiffAccept` | Accept proposed changes |
| `:ClaudeCodeDiffDeny` | Reject proposed changes |

## Config options (opts)

```lua
opts = {
  port_range = { min = 10000, max = 65535 },
  auto_start = true,
  log_level = "info",       -- "trace", "debug", "info", "warn", "error"
  terminal_cmd = nil,       -- set to "~/.claude/local/claude" for local install
  focus_after_send = false,
  track_selection = true,
  visual_demotion_delay_ms = 50,

  terminal = {
    split_side = "right",           -- "left" or "right"
    split_width_percentage = 0.30,
    provider = "auto",              -- "auto", "snacks", "native", "external", "none"
    auto_close = true,
    snacks_win_opts = {},
  },

  diff_opts = {
    layout = "vertical",            -- "vertical" or "horizontal"
    open_in_new_tab = false,
    keep_terminal_focus = false,
    hide_terminal_in_new_tab = false,
  },
}
```

## Diff management

- Accept: `:w` or `:ClaudeCodeDiffAccept`
- Deny: `:q` or `:ClaudeCodeDiffDeny`

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Claude not connecting | `:ClaudeCodeStatus`, check `~/.claude/ide/` for lock file |
| Debug logs | `log_level = "debug"` |
| Terminal issues | `provider = "native"` |
