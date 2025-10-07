local removals = {
  -- Remove default keymaps from LazyVim that do not work for me
  n = {
    "<leader>n",
    "<leader>e",
    "<leader>E",
    "<leader>fg",
    "<leader>|",
    "<leader>-",
    "gc",
    "gcc",
    "gco",
    "gcO",
    "<leader>uC",
    "<leader>l",
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

local function goto_preview_action(method)
  return function()
    require("goto-preview")[method]()
  end
end

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

    -- Allow moving the cursor through wrapped lines with j, k, <Up> and <Down>
    -- http://www.reddit.com/r/vim/comments/2k4cbr/problem_with_gj_and_gk/
    -- empty mode is same as using <cmd> :map
    -- also don't use g[j|k] when in operator pending mode, so it doesn't alter d, y or c behaviour
    ["j"] = { 'v:count || mode(1)[0:1] == "no" ? "j" : "gj"', desc = "Move down", expr = true },
    ["k"] = { 'v:count || mode(1)[0:1] == "no" ? "k" : "gk"', desc = "Move up", expr = true },
    ["<Up>"] = { 'v:count || mode(1)[0:1] == "no" ? "k" : "gk"', desc = "Move up", expr = true },
    ["<Down>"] = {
      'v:count || mode(1)[0:1] == "no" ? "j" : "gj"',
      desc = "Move down",
      expr = true,
    },
  },

  v = {
    ["<Up>"] = { 'v:count || mode(1)[0:1] == "no" ? "k" : "gk"', desc = "Move up", expr = true },
    ["<Down>"] = {
      'v:count || mode(1)[0:1] == "no" ? "j" : "gj"',
      desc = "Move down",
      expr = true,
    },
    ["<"] = { "<gv", desc = "Indent line" },
    [">"] = { ">gv", desc = "Indent line" },
  },

  x = {
    ["<leader>/"] = {
      function()
        return require("vim._comment").operator()
      end,
      desc = "Toggle Comment",
      expr = true,
    },

    ["j"] = { 'v:count || mode(1)[0:1] == "no" ? "j" : "gj"', desc = "Move down", expr = true },
    ["k"] = { 'v:count || mode(1)[0:1] == "no" ? "k" : "gk"', desc = "Move up", expr = true },
    -- Don't copy the replaced text after pasting in visual mode
    -- https://vim.fandom.com/wiki/Replace_a_word_with_yanked_text#Alternative_mapping_for_paste
    ["p"] = { 'p:let @+=@0<CR>:let @"=@0<CR>', desc = "Dont copy replaced text", silent = true },
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
    ["<leader>ft"] = {
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

    -- Terminal
    ["<leader><space>"] = {
      function()
        Snacks.terminal()
      end,
      desc = "Terminal",
    },
  },

  t = {
    ["<leader><space>"] = {
      function()
        Snacks.terminal()
      end,
      desc = "Terminal",
    },
  },
}

keymaps.goto_preview = {
  n = {
    ["<leader>p"] = {
      "",
      desc = "+preview",
    },
    ["<leader>pd"] = {
      goto_preview_action("goto_preview_definition"),
      desc = "Preview Definition",
    },
    ["<leader>pt"] = {
      goto_preview_action("goto_preview_type_definition"),
      desc = "Preview Type",
    },
    ["<leader>pi"] = {
      goto_preview_action("goto_preview_implementation"),
      desc = "Preview Implementation",
    },
    ["<leader>pr"] = {
      goto_preview_action("goto_preview_references"),
      desc = "Preview References",
    },
  },
}

keymaps.windows = {
  n = {
    ["<S-Left>"] = { "<C-w><", desc = "Decrease width" },
    ["<S-Right>"] = { "<C-w>>", desc = "Increase width" },
    ["<S-Up>"] = { "<C-w>-", desc = "Decrease height" },
    ["<S-Down>"] = { "<C-w>+", desc = "Increase height" },
  },
}

keymaps.lsp = {
  n = {
    ["<leader>l"] = {
      "",
      desc = "+lsp",
    },
    ["<leader>lr"] = {
      function()
        Snacks.picker.lsp_references()
      end,
      desc = "LSP References",
    },
    ["<leader>ld"] = {
      function()
        Snacks.picker.lsp_definitions()
      end,
      desc = "LSP Definitions",
    },
    ["<leader>li"] = {
      function()
        Snacks.picker.lsp_implementations()
      end,
      desc = "LSP Implementations",
    },

    ["K"] = {
      function()
        vim.lsp.buf.hover()
      end,
      desc = "Hover",
    },

    ["<leader>l["] = {
      function()
        ---@diagnostic disable-next-line: deprecated
        vim.diagnostic.goto_prev()
      end,
      desc = "LSP Previous diagnostic",
    },

    ["<leader>l]"] = {
      function()
        ---@diagnostic disable-next-line: deprecated
        vim.diagnostic.goto_next()
      end,
      desc = "LSP Next diagnostic",
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

keymaps.dap = {
  n = {
    [".."] = {
      function()
        require("dap").step_over()
      end,
      desc = "Step Over",
    },
  },
}

keymaps.sidekick = {
  n = {
    ["<leader><leader>"] = {
      function()
        require("sidekick.cli").toggle({
          backend = "tmux",
          focus = false,
        })
      end,
      desc = "Toggle Sidekick CLI",
    },
    ["<leader>aa"] = {
      function()
        require("sidekick.cli").toggle({
          backend = "tmux",
        })
      end,
      desc = "Toggle Sidekick CLI",
    },
    ["<leader>ap"] = {
      function()
        require("sidekick.cli").select_prompt()
      end,
      desc = "Select Sidekick Prompt",
    },
    ["<leader>af"] = {
      function()
        require("sidekick.cli").focus()
      end,
      desc = "Focus Sidekick CLI",
    },
    ["<leader>au"] = {
      function()
        require("sidekick.nes").update()
      end,
      desc = "Update NES Suggestions",
    },
    ["<leader>aj"] = {
      function()
        require("sidekick.nes").jump()
      end,
      desc = "Jump to NES Hunk",
    },
    ["<leader>aA"] = {
      function()
        require("sidekick.nes").apply()
      end,
      desc = "Apply NES Edits",
    },
    ["<leader>ac"] = {
      function()
        require("sidekick").clear()
      end,
      desc = "Clear Sidekick",
    },
  },
}

keymaps.kulala = {
  n = {
    ["<leader>R"] = {
      "",
      desc = "+rest",
    },
    ["<leader>Rb"] = {
      function()
        require("kulala").scratchpad()
      end,
      desc = "Open scratchpad",
    },
    ["<leader>Rc"] = {
      function()
        require("kulala").copy()
      end,
      desc = "Copy as cURL",
    },
    ["<leader>RC"] = {
      function()
        require("kulala").from_curl()
      end,
      desc = "Paste from curl",
    },
    ["<leader>Rg"] = {
      function()
        require("kulala").download_graphql_schema()
      end,
      desc = "Download GraphQL schema",
    },
    ["<leader>Ri"] = {
      function()
        require("kulala").inspect()
      end,
      desc = "Inspect current request",
    },
    ["<leader>Rn"] = {
      function()
        require("kulala").jump_next()
      end,
      desc = "Jump to next request",
    },
    ["<leader>Rp"] = {
      function()
        require("kulala").jump_prev()
      end,
      desc = "Jump to previous request",
    },
    ["<leader>Rq"] = {
      function()
        require("kulala").close()
      end,
      desc = "Close window",
    },
    ["<leader>Rr"] = {
      function()
        require("kulala").replay()
      end,
      desc = "Replay the last request",
    },
    ["<leader>Rs"] = {
      function()
        require("kulala").run()
      end,
      desc = "Send the request",
    },
    ["<leader>RS"] = {
      function()
        require("kulala").show_stats()
      end,
      desc = "Show stats",
    },
    ["<leader>Rt"] = {
      function()
        require("kulala").toggle_view()
      end,
      desc = "Toggle headers/body",
    },
  },
}

keymaps.git = {
  n = {
    ["<leader>gR"] = {
      "",
      desc = "+review",
    },
    ["<leader>gRs"] = {
      function()
        vim.cmd([[Octo review start]])
      end,
      desc = "Start Review",
    },
    ["<leader>gRc"] = {
      function()
        vim.cmd([[Octo review close]])
      end,
      desc = "Close Review",
    },
    ["<leader>gRr"] = {
      function()
        vim.cmd([[Octo review resume]])
      end,
      desc = "Resume Review",
    },
    ["<leader>gRb"] = {
      function()
        vim.cmd([[Octo review browse]])
      end,
      desc = "Browse Review",
    },
    ["<leader>gRd"] = {
      function()
        vim.cmd([[Octo review discard]])
      end,
      desc = "Discard Review",
    },
    ["<leader>gRS"] = {
      function()
        vim.cmd([[Octo review submit]])
      end,
      desc = "Submit Review",
    },

    ["<leader>gP"] = {
      "",
      desc = "+pr",
    },
    ["<leader>gPc"] = {
      function()
        vim.cmd([[Octo pr checkout]])
      end,
      desc = "Checkout PR",
    },
    ["<leader>gPl"] = {
      function()
        vim.cmd([[Octo pr list]])
      end,
      desc = "List PRs",
    },
    ["<leader>gPm"] = {
      function()
        vim.cmd([[Octo pr merge]])
      end,
      desc = "Merge PR",
    },
    ["<leader>gPR"] = {
      function()
        vim.cmd([[Octo pr reload]])
      end,
      desc = "Reload PR",
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
