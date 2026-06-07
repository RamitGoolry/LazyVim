return {
  dir = vim.fn.stdpath("config") .. "/vendor/sidekick.nvim",
  name = "sidekick.nvim",
  opts = {
    ai = {
      provider = "claude",
    },
    nes = {
      enabled = false,
      auto_fetch = false,
    },
    cli = {
      mux = {
        enabled = false,
      },
    },
  },
}
