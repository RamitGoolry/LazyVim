return {
  {
    "epwalsh/obsidian.nvim",
    version = "*",
    lazy = false,
    ft = "markdown",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      vim.opt.conceallevel = 2
      local has_cmp = pcall(require, "cmp")
      local obsidian = require("obsidian")
      obsidian.setup({
        workspaces = {
          {
            name = "notes",
            path = vim.fn.expand("~/Desktop/Notes"),
          },
        },
        notes_subdir = "Main Notes",
        completion = {
          nvim_cmp = has_cmp,
          min_chars = 2,
        },
        new_notes_location = "notes_subdir",
        note_id_func = function(title)
          return title
        end,
        disable_frontmatter = false,
        note_frontmatter_func = function(note)
          if note.title then
            note:add_alias(note.title)
          end

          local out = { id = note.id, aliases = note.aliases }

          if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
            for k, v in pairs(note.metadata) do
              out[k] = v
            end
          end

          return out
        end,
        picker = {
          name = "telescope.nvim",
          note_mappings = {
            new = "<C-x>",
            insert_link = "<C-l>",
          },
          tag_mappings = {
            tag_note = "<C-x>",
            insert_tag = "<C-l>",
          },
        },
      })
    end,
  },
}
