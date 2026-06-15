return {
  {
    "barrettruth/diffs.nvim",
    lazy = false,
    init = function()
      vim.g.diffs = {
        extra_filetypes = { "diff", "patch" },
        integrations = {
          gitsigns = true,
        },
        conflict = {
          keymaps = {
            ours = "<leader>co",
            theirs = "<leader>ct",
            both = "<leader>ca",
            none = "dx",
            next = "]x",
            prev = "[x",
          },
        },
      }
    end,
    config = function()
      local function is_diffs_buffer(bufnr)
        return vim.api.nvim_buf_get_name(bufnr):match("^diffs://") ~= nil
      end

      local function hunk_under_cursor(bufnr)
        local ok_generated, generated = pcall(require, "diffs.generated")
        local ok_hunks, hunks = pcall(require, "diffs.hunks")
        if not ok_generated or not ok_hunks then
          return nil
        end

        return hunks.hunk_at_line(generated.hunks(bufnr), vim.api.nvim_win_get_cursor(0)[1])
      end

      local function refresh(bufnr)
        local ok, commands = pcall(require, "diffs.commands")
        if ok then
          commands.read_buffer(bufnr)
        end
      end

      local function toggle_hunk()
        local bufnr = vim.api.nvim_get_current_buf()
        local hunk = hunk_under_cursor(bufnr)
        if not hunk then
          vim.notify("No diff hunk under cursor", vim.log.levels.WARN, { title = "diffs.nvim" })
          return
        end

        local actions = require("diffs.actions")
        local changed = hunk.can_put and actions.put_hunk(bufnr) or hunk.can_obtain and actions.obtain_hunk(bufnr)
        if changed then
          refresh(bufnr)
        end
      end

      local function toggle_range()
        local bufnr = vim.api.nvim_get_current_buf()
        local hunk = hunk_under_cursor(bufnr)
        if not hunk then
          vim.notify("No diff hunk under cursor", vim.log.levels.WARN, { title = "diffs.nvim" })
          return
        end

        local start_line = vim.api.nvim_buf_get_mark(bufnr, "<")[1]
        local finish_line = vim.api.nvim_buf_get_mark(bufnr, ">")[1]
        if finish_line < start_line then
          start_line, finish_line = finish_line, start_line
        end

        local actions = require("diffs.actions")
        local changed = hunk.can_put and actions.put_range(bufnr, start_line, finish_line)
          or hunk.can_obtain and actions.obtain_range(bufnr, start_line, finish_line)
        if changed then
          refresh(bufnr)
        end
      end

      vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
        group = vim.api.nvim_create_augroup("DiffsToggleStageKeymap", { clear = true }),
        callback = function(args)
          if not is_diffs_buffer(args.buf) then
            return
          end

          vim.keymap.set("n", "s", toggle_hunk, { buffer = args.buf, silent = true, desc = "Stage / unstage hunk" })
          vim.keymap.set("x", "s", toggle_range, { buffer = args.buf, silent = true, desc = "Stage / unstage selection" })
        end,
      })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    optional = true,
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      if not vim.tbl_contains(opts.ensure_installed, "diff") then
        table.insert(opts.ensure_installed, "diff")
      end
      return opts
    end,
  },
}
