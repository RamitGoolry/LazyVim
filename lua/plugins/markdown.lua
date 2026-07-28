return {
  -- Disable markdownlint from the markdown extra
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = vim.tbl_filter(function(tool)
        return tool ~= "markdownlint-cli2"
      end, opts.ensure_installed or {})
    end,
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      for _, ft in ipairs({ "markdown", "markdown.mdx" }) do
        opts.formatters_by_ft[ft] = vim.tbl_filter(function(formatter)
          return formatter ~= "markdownlint-cli2"
        end, opts.formatters_by_ft[ft] or {})
      end
    end,
  },
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
