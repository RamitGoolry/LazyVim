local excluded_colors = {
  "blue",
  "catppuccin",
  "catppuccin-latte",
  "darkblue",
  "delek",
  "desert",
  "elflord",
  "elfnord",
  "evening",
  "habamax",
  "industry",
  "koehler",
  "lunaperche",
  "morning",
  "murphy",
  "kanagawa-lotus",
  "pablo",
  "peachpuff",
  "retrobox",
  "quiet",
  "ron",
  "shine",
  "slate",
  "sorbet",
  "torte",
  "tokyonight-day",
  "unokai",
  "vim",
  "zaibatsu",
  "zellner",
}

local excluded = {}
for _, name in ipairs(excluded_colors) do
  excluded[name] = true
end

return {
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      opts.picker = opts.picker or {}
      opts.picker.sources = opts.picker.sources or {}

      local colors = opts.picker.sources.colorschemes or {}
      local original_transform = colors.transform
      if type(original_transform) == "string" then
        local ok, picker_config = pcall(require, "snacks.picker.config")
        if ok then
          original_transform = picker_config.transform({ transform = original_transform })
        else
          original_transform = nil
        end
      end

      colors.transform = function(item, ctx)
        if excluded[item.text] then
          return false
        end
        if original_transform then
          return original_transform(item, ctx)
        end
      end

      opts.picker.sources.colorschemes = colors
    end,
  },
  {
    "rebelot/kanagawa.nvim",
    lazy = true,
  },
  {
    "nyoom-engineering/oxocarbon.nvim",
    lazy = true,
  },
  {
    "sainnhe/sonokai",
    lazy = true,
  },
  {
    "navarasu/onedark.nvim",
    lazy = true,
  },
  {
    "ellisonleao/gruvbox.nvim",
    lazy = true,
  },
}
