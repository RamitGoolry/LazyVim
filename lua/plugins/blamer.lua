return {
  "APZelos/blamer.nvim",
  event = "BufReadPost",
  init = function()
    vim.g.blamer_enabled = 1
  end,
}
