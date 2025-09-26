return {
  "marilari88/twoslash-queries.nvim",
  ft = { "typescript", "typescriptreact", "ts", "tsx" },
  config = function()
    require("twoslash-queries").setup({
      multi_line = true,
      is_enabled = true,
      highlight = "Type",
    })
  end,
}
