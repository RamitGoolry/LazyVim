local removals = {
  -- Remove default keymaps from LazyVim that do not work for me
  n = {
    "<leader>n",
    "<leader>fg",
    "<leader>|",
    "<leader>-",
    "gc",
    "gcc",
    "gco",
    "gcO",
    "<leader>uC",
    "<leader>T",
  },
  x = {
    "gc",
  },
  o = {
    "gc",
  },
}

for mode, keys in pairs(removals) do
  for _, lhs in ipairs(keys) do
    pcall(vim.keymap.del, mode, lhs)
  end
end

local Snacks = require("snacks")

local keymaps = {}

keymaps.general = {
  n = {
    ["<Esc>"] = {
      function()
        vim.cmd([[noh]])
      end,
      desc = "Clear highlights",
    },

    -- Switching betwen windows
    ["<C-h>"] = { "<C-w>h", desc = "Window left" },
    ["<C-j>"] = { "<C-w>j", desc = "Window down" },
    ["<C-k>"] = { "<C-w>k", desc = "Window up" },
    ["<C-l>"] = { "<C-w>l", desc = "Window right" },

    -- Splitting Windows
    ["<leader>%"] = {
      function()
        vim.cmd([[vsplit]])
      end,
      desc = "Split Window Right",
    },
    ['<leader>"'] = {
      function()
        vim.cmd([[split]])
      end,
      desc = "Split Window Bottom",
    },

    ["<leader>/"] = {
      function()
        return require("vim._comment").operator() .. "_"
      end,
      desc = "Toggle Comment",
      expr = true,
    },
  },
  x = {
    ["<leader>/"] = {
      function()
        return require("vim._comment").operator()
      end,
      desc = "Toggle Comment",
      expr = true,
    },
  },
}

keymaps.lsp = {
  n = {
    ["<leader>rn"] = {
      function()
        -- TODO: Rename
        vim.notify("Rename not implemented yet")
      end,
      desc = "Rename",
    },
  },
}

keymaps.snacks = {
  n = {
    -- LazyGit
    ["<leader>lg"] = {
      function()
        Snacks.lazygit.open()
      end,
      desc = "LazyGit",
    },

    -- Picker
    ["<leader>fg"] = {
      function()
        Snacks.picker.grep()
      end,
      desc = "Grep Files",
    },
    ["<leader>ff"] = {
      function()
        Snacks.picker.files({
          finder = "files",
          format = "file",
          show_empty = true,
          hidden = true,
          ignored = true,
          follow = false,
          supports_live = true,
        })
      end,
      desc = "Find files",
    },

    -- Explorer
    ["<leader>n"] = {
      function()
        Snacks.explorer({
          show_empty = true,
          hidden = true,
          ignored = true,
          follow = false,
          supports_live = true,
        })
      end,
      desc = "File Explorer",
    },

    -- Themes
    ["<leader>th"] = {
      function()
        Snacks.picker.colorschemes()
      end,
      desc = "Themes",
    },

    -- Undotree
    ["<leader>u"] = {
      function()
        Snacks.picker.undo()
      end,
      desc = "Undotree",
    },

    -- LSP
    ["<leader>tr"] = {
      function()
        Snacks.picker.lsp_references()
      end,
      desc = "LSP References",
    },
    ["<leader>td"] = {
      function()
        Snacks.picker.lsp_definitions()
      end,
      desc = "LSP Definitions",
    },
    ["<leader>ti"] = {
      function()
        Snacks.picker.lsp_implementations()
      end,
      desc = "LSP Implementations",
    },
  },
}

keymaps.trouble = {
  n = {
    ["<leader>T"] = {
      "<cmd>Trouble diagnostics toggle<cr>",
      desc = "Trouble Diagnostics",
    },
  },
}

local function apply_keymaps(collection)
  for _, modes in pairs(collection) do
    for mode, mappings in pairs(modes) do
      for lhs, mapping in pairs(mappings) do
        local rhs = mapping
        local opts = { silent = true }

        if type(mapping) == "table" then
          rhs = mapping[1]
          for key, value in pairs(mapping) do
            if key ~= 1 then
              opts[key] = value
            end
          end
        end

        vim.keymap.set(mode, lhs, rhs, opts)
      end
    end
  end
end

apply_keymaps(keymaps)
