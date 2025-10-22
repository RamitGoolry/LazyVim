return {
  "pwntester/octo.nvim",
  opts = {
    default_to_projects_v2 = true,
    suppress_missing_scope = {
      projects_v2 = false,
    },
  },
  config = function(_, opts)
    -- Override queries with local patched version (removes deprecated projectCards)
    package.loaded["octo.gh.queries"] = nil
    local queries = dofile(vim.fn.stdpath("config") .. "/lua/plugins/octo-nvim/lua/octo/gh/queries.lua")
    package.preload["octo.gh.queries"] = function() return queries end

    require("octo").setup(opts)
  end,
}
