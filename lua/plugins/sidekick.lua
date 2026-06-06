local function sidekick_backend()
  return vim.env.HERDR_ENV == "1" and "herdr" or "tmux"
end

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
        enabled = true,
        backend = sidekick_backend(),
      },
    },
  },
}
