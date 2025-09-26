local removals = {
  n = {
    "<leader>n",
    "<leader>fg",
  },
}

for mode, keys in pairs(removals) do
  for _, lhs in ipairs(keys) do
    pcall(vim.keymap.del, mode, lhs)
  end
end

local Snacks = require("snacks")

local keymaps = {}

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
