return {
  {
    "ravitemer/mcphub.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    -- Installs/updates the mcp-hub binary globally
    build = "npm install -g mcp-hub@latest",
    config = function()
      require("mcphub").setup()
    end,
  },
}
