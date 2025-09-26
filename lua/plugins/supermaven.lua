return {
  "supermaven-inc/supermaven-nvim",
  lazy = false,
  opts = {
    keymaps = {
      accept_word = "<C-j>",
      accept_suggestion = "<S-Tab>",
      clear_suggestion = "<C-]>",
    },
    ignore_filetypes = {},
  },
  config = function(_, opts)
    require("supermaven-nvim").setup(opts)
  end,
}
