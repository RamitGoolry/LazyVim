-- Swift LSP and Treesitter configuration for LazyVim
-- Configures sourcekit-lsp (bundled with Xcode) and Swift treesitter parser

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, { "swift" })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        sourcekit = {
          mason = false,
          cmd = { "xcrun", "sourcekit-lsp" },
        },
      },
    },
  },
}
