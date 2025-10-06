local function get_js_debug_paths()
  local ok, registry = pcall(require, "mason-registry")
  if ok then
    local success, package = pcall(function()
      return registry.get_package("js-debug-adapter")
    end)
    if success and package and package:is_installed() and package.get_install_path then
      local install = package:get_install_path()
      return install, install .. "/js-debug-adapter"
    end
  end
  local fallback = vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter"
  return fallback, fallback .. "/js-debug-adapter"
end

return {
  {
    "mxsdev/nvim-dap-vscode-js",
    dependencies = { "mfussenegger/nvim-dap" },
    config = function()
      local dap = require("dap")
      local debugger_root, debugger_cmd = get_js_debug_paths()

      require("dap-vscode-js").setup({
        debugger_path = debugger_root .. "/js-debug",
        debugger_cmd = { debugger_cmd },
        adapters = { "pwa-node", "pwa-chrome", "pwa-msedge", "node-terminal", "pwa-extensionHost" },
      })

      local function with_defaults(config)
        return vim.tbl_deep_extend("keep", config, {
          cwd = "${workspaceFolder}",
          skipFiles = { "<node_internals>/**", "${workspaceFolder}/node_modules/**" },
          resolveSourceMapLocations = {
            "${workspaceFolder}/**",
            "!**/node_modules/**",
          },
        })
      end

      local function add_configuration(language, config)
        dap.configurations[language] = dap.configurations[language] or {}
        for _, existing in ipairs(dap.configurations[language]) do
          if existing.name == config.name then
            return
          end
        end
        table.insert(dap.configurations[language], config)
      end

      local node_configs = {
        with_defaults({
          type = "pwa-node",
          request = "launch",
          name = "Launch file",
          program = "${file}",
          sourceMaps = true,
          console = "integratedTerminal",
        }),
        with_defaults({
          type = "pwa-node",
          request = "launch",
          name = "Launch TS file",
          program = "${file}",
          runtimeExecutable = "node",
          runtimeArgs = { "--loader", "tsx" },
          sourceMaps = true,
          console = "integratedTerminal",
        }),
        with_defaults({
          type = "pwa-node",
          request = "launch",
          name = "Launch npm run dev",
          runtimeExecutable = "npm",
          runtimeArgs = { "run", "dev" },
          sourceMaps = true,
          console = "integratedTerminal",
          internalConsoleOptions = "neverOpen",
        }),
        with_defaults({
          type = "pwa-node",
          request = "attach",
          name = "Attach to process",
          processId = require("dap.utils").pick_process,
        }),
      }

      local chrome_config = with_defaults({
        type = "pwa-chrome",
        request = "launch",
        name = "Launch Chrome to localhost",
        url = "http://localhost:3000",
        webRoot = "${workspaceFolder}",
        sourceMaps = true,
      })

      local filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" }
      for _, language in ipairs(filetypes) do
        for _, cfg in ipairs(node_configs) do
          add_configuration(language, vim.deepcopy(cfg))
        end
        if language:find("react") then
          add_configuration(language, vim.deepcopy(chrome_config))
        end
      end
    end,
  },

  {
    "jay-babu/mason-nvim-dap.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      if not vim.tbl_contains(opts.ensure_installed, "js-debug-adapter") then
        table.insert(opts.ensure_installed, "js-debug-adapter")
      end
    end,
  },
}
