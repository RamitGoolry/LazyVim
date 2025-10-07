return {
  "olimorris/persisted.nvim",
  lazy = false,
  config = function()
    require("persisted").setup({
      save_dir = vim.fn.expand(vim.fn.stdpath("data") .. "/sessions/"),
      silent = false,
      use_git_branch = true,
      default_branch = "main",
      autosave = true,
      should_autosave = nil,
      autoload = true,
      on_autoload_no_session = nil,
      follow_cwd = true,
      allowed_dirs = nil,
      ignored_dirs = nil,
      ignored_branches = nil,
      telescope = {
        reset_prompt = true,
        mappings = {
          change_branch = "<c-b>",
          copy_session = "<c-c>",
          delete_session = "<c-d>",
        },
        icons = {
          branch = " ",
          dir = " ",
          selected = " ",
        },
      },
    })

    -- Close unwanted buffers before saving session
    local group = vim.api.nvim_create_augroup("PersistedHooks", { clear = true })
    vim.api.nvim_create_autocmd("User", {
      pattern = "PersistedSavePre",
      group = group,
      callback = function()
        -- Close kulala and octo buffers before saving
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_valid(buf) then
            local bufname = vim.api.nvim_buf_get_name(buf)
            if bufname:match("^kulala://") or bufname:match("^octo://") then
              vim.api.nvim_buf_delete(buf, { force = true })
            end
          end
        end
      end,
    })
  end,
}
