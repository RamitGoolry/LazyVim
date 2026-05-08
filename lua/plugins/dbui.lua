return {
  {
    "kristijanhusak/vim-dadbod-ui",
    init = function()
      vim.g.db_ui_execute_on_save = 1

      -- DBUI SQL buffers can hit Neovim's built-in sqlcomplete before it has
      -- fully defined its drill-in/out helpers, leaving g:loaded_sql_completion
      -- set and causing E117 for sqlcomplete#DrillOutOfColumns(). Force a clean
      -- load so the default SQL omni-completion arrow-key mappings keep working.
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "sql",
        callback = function()
          vim.cmd("unlet! g:loaded_sql_completion")
          vim.cmd("runtime autoload/sqlcomplete.vim")
        end,
      })
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
