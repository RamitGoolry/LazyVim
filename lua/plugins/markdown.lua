return {
  -- Disable markdownlint from the markdown extra
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      -- Remove markdownlint from markdown filetypes
      opts.linters_by_ft.markdown = vim.tbl_filter(function(linter)
        return linter ~= "markdownlint" and linter ~= "markdownlint-cli2"
      end, opts.linters_by_ft.markdown or {})
    end,
  },
  -- Disable marksman LSP for markdown
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      opts.servers.marksman = { enabled = false }
    end,
  },
}
