return {
  {
    "stevearc/overseer.nvim",
    opts = function(_, opts)
      local config = require("overseer.config")

      opts.component_aliases = opts.component_aliases or {}

      local default_components = opts.component_aliases.default
        or vim.deepcopy(config.component_aliases.default)

      if default_components then
        opts.component_aliases.default = vim.tbl_filter(function(component)
          if type(component) == "string" then
            return component ~= "on_complete_notify"
          end
          if type(component) == "table" then
            return component[1] ~= "on_complete_notify"
          end
          return true
        end, default_components)
      end
    end,
  },
}
