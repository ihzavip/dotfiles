-- MQL5: clang-format for layout, the MetaEditor compiler for diagnostics.
-- ponytail: MT5 path hardcoded; make it a per-project var if a second terminal shows up.
local MT5 = "/home/lucy/.wine/drive_c/Program Files/MetaTrader 5"

return {
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.mql5 = { "clang_format" }
      opts.formatters = opts.formatters or {}
      -- clang-format does not know .mq5; tell it the file is C++
      opts.formatters.clang_format = { args = { "--assume-filename=x.cpp" } }
    end,
  },
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      require("lint").linters.mql5 = {
        cmd = "sh",
        stdin = false,
        append_fname = true, -- lands in $0
        args = {
          "-c",
          -- metaeditor only accepts a /compile: path relative to its own folder
          'MT5="' .. MT5 .. '"; case "$0" in "$MT5"/*) ;; *) exit 0 ;; esac; f="${0#$MT5/}"; '
            .. 'cd "$MT5" && wine metaeditor64.exe /compile:"$f" '
            .. "/log:'C:\\tmp\\nvim-mql5.log' >/dev/null 2>&1; "
            .. "iconv -f UTF-16LE -t UTF-8 ~/.wine/drive_c/tmp/nvim-mql5.log 2>/dev/null",
        },
        stream = "stdout",
        ignore_exitcode = true,
        parser = require("lint.parser").from_pattern(
          "([^(]+)%((%d+),(%d+)%) : (%a+) (%d+): (.+)",
          { "file", "lnum", "col", "severity", "code", "message" },
          {
            error = vim.diagnostic.severity.ERROR,
            warning = vim.diagnostic.severity.WARN,
            information = vim.diagnostic.severity.INFO,
          },
          { source = "metaeditor" }
        ),
      }
      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters_by_ft.mql5 = { "mql5" }
    end,
  },
}
