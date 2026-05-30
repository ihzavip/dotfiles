return {
  {
    "mfussenegger/nvim-dap",
    config = function()
      vim.fn.sign_define("DapBreakpoint",          { text = "●", texthl = "DiagnosticError",   linehl = "DapBreakpointLine",  numhl = "" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DiagnosticWarn",    linehl = "DapBreakpointLine",  numhl = "" })
      vim.fn.sign_define("DapLogPoint",            { text = "◉", texthl = "DiagnosticInfo",    linehl = "",                   numhl = "" })
      vim.fn.sign_define("DapStopped",             { text = "▶", texthl = "DiagnosticOk",      linehl = "DapStoppedLine",     numhl = "" })
      vim.fn.sign_define("DapBreakpointRejected",  { text = "○", texthl = "DiagnosticError",   linehl = "",                   numhl = "" })
      vim.api.nvim_set_hl(0, "DapBreakpointLine", { bg = "#3c1010" })
      vim.api.nvim_set_hl(0, "DapStoppedLine",    { bg = "#1a3a1a" })
      local dap = require("dap")
      dap.adapters.codelldb = {
        type = "server",
        port = "${port}",
        executable = {
          command = vim.fn.stdpath("data") .. "/mason/bin/codelldb",
          args = { "--port", "${port}" },
        },
      }
      dap.configurations.c = {
        {
          name = "Launch",
          type = "codelldb",
          request = "launch",
          program = "/home/lucy/Documents/c/build/Debug/topdown",
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
          args = {},
        },
      }
    end,
  },
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "codelldb" })
    end,
  },
}
