return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    table.insert(opts.sections.lualine_x, 2, {
      function()
        local sidekick = require("sidekick")
        local status = sidekick.status()

        if not status or status == "" then
          return ""
        end

        local icons = {
          error = " ",
          warning = " ",
          normal = " ",
        }

        return icons[status] or status
      end,
      cond = function()
        return package.loaded["sidekick"] ~= nil
      end,
    })
  end,
}