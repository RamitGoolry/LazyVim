return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-treesitter/nvim-treesitter",
      "nvim-neotest/neotest-python",
      "marilari88/neotest-vitest",
      "nvim-neotest/neotest-plenary",
    },
    opts = function(_, opts)
      local neotest_python = require("neotest-python")
      local neotest_vitest = require("neotest-vitest")
      local neotest_plenary = require("neotest-plenary")

      opts.adapters = {
        neotest_python({
          dap = { justMyCode = false },
          runner = "pytest",
          python = function()
            return vim.fn.exepath("python3")
          end,
        }),
        neotest_vitest({
          filter_dir = function(name)
            return name ~= "node_modules"
          end,
        }),
        neotest_plenary,
      }

      return opts
    end,
  },
}
