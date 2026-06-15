return {
  {
    "barrettruth/diffs.nvim",
    lazy = false,
    init = function()
      vim.g.diffs = {
        extra_filetypes = { "diff", "patch" },
        integrations = {
          gitsigns = true,
        },
        conflict = {
          keymaps = {
            ours = "<leader>co",
            theirs = "<leader>ct",
            both = "<leader>ca",
            none = "dx",
            next = "]x",
            prev = "[x",
          },
        },
      }
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    optional = true,
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      if not vim.tbl_contains(opts.ensure_installed, "diff") then
        table.insert(opts.ensure_installed, "diff")
      end
      return opts
    end,
  },
}
