return {
  {
    "mfussenegger/nvim-dap",
    opts = function()
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
          program = function()
            local cwd = vim.fn.getcwd()
            local name = vim.fn.fnamemodify(cwd, ":t")
            local candidates = {
              cwd .. "/build/Debug/" .. name,
              cwd .. "/build/" .. name,
              cwd .. "/build/Release/" .. name,
            }
            for _, path in ipairs(candidates) do
              if vim.fn.filereadable(path) == 1 then
                return path
              end
            end
            return vim.fn.input("Binary: ", cwd .. "/build/Debug/", "file")
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
          args = {},
        },
      }
    end,
  },
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "codelldb" })
    end,
  },
}
