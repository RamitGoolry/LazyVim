return {
  "rmagatti/goto-preview",
  event = "VeryLazy",
  config = function()
    require("goto-preview").setup({
      height = 20,
      width = 80,
      references = {
        provider = "snacks",
      },
    })
  end,
}
