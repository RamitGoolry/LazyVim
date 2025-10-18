-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Auto-reload files when changed externally
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
  pattern = "*",
  command = "if mode() != 'c' | checktime | endif",
  desc = "Check if file has changed outside of Neovim",
})

vim.api.nvim_create_autocmd("FileChangedShellPost", {
  pattern = "*",
  command = "echohl WarningMsg | echo 'File changed on disk. Buffer reloaded.' | echohl None",
  desc = "Notify when file is reloaded",
})

-- Aggressive polling for external file changes (e.g., AI agents)
local timer = vim.uv.new_timer()
timer:start(
  500, -- start after 500ms
  500, -- repeat every 500ms
  vim.schedule_wrap(function()
    -- Only check if not in command-line mode
    if vim.fn.mode() ~= "c" then
      vim.cmd("checktime")
    end
  end)
)
