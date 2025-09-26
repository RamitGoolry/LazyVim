return {
  {
    "kristijanhusak/vim-dadbod-ui",
    init = function()
      vim.g.db_ui_execute_on_save = 1
    end,
  },

  {
    "folke/edgy.nvim",
    optional = true,
    opts = function(_, opts)
      if not opts.bottom then
        return
      end

      for _, panel in ipairs(opts.bottom) do
        if panel.ft == "dbout" then
          panel.size = panel.size or {}
          panel.size.height = panel.size.height or 0.35
          break
        end
      end
    end,
  },
}
