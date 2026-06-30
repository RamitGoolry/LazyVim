return {
  {
    "tiny-dfr-nvim-bridge",
    dir = vim.fn.stdpath("config"),
    event = "VeryLazy",
    config = function()
      require("tiny_dfr_bridge").setup()
    end,
  },
}
