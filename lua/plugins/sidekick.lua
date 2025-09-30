return {
  "folke/sidekick.nvim",
  opts = {
    ai = {
      provider = "claude",
    },
    nes = {
      enabled = true,
      auto_fetch = true,
    },
    backend = "tmux",
  },
  keys = {
    {
      "<leader>aa",
      function()
        require("sidekick.cli").toggle({
          backend = "tmux",
        })
      end,
      desc = "Toggle Sidekick CLI",
    },
    {
      "<leader>ap",
      function()
        require("sidekick.cli").select_prompt()
      end,
      desc = "Select Sidekick Prompt",
    },
    {
      "<leader>af",
      function()
        require("sidekick.cli").focus()
      end,
      desc = "Focus Sidekick CLI",
    },
    {
      "<leader>au",
      function()
        require("sidekick.nes").update()
      end,
      desc = "Update NES Suggestions",
    },
    {
      "<leader>aj",
      function()
        require("sidekick.nes").jump()
      end,
      desc = "Jump to NES Hunk",
    },
    {
      "<leader>aA",
      function()
        require("sidekick.nes").apply()
      end,
      desc = "Apply NES Edits",
    },
    {
      "<leader>ac",
      function()
        require("sidekick").clear()
      end,
      desc = "Clear Sidekick",
    },
  },
}
