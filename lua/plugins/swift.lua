-- Swift/iOS development support for LazyVim
-- sourcekit-lsp (Xcode-bundled), treesitter, and xcodebuild.nvim for project integration
-- Requires: brew install xcode-build-server xcbeautify

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, { "swift" })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        sourcekit = {
          mason = false,
          cmd = { "xcrun", "sourcekit-lsp" },
        },
      },
    },
  },
  {
    "wojciech-kulik/xcodebuild.nvim",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    opts = {
      show_build_progress_bar = false,
      logs = {
        auto_open_on_success_build = false,
        auto_open_on_failed_build = true,
        auto_focus = false,
      },
    },
    ft = { "swift" },
    cmd = {
      "XcodebuildSetup",
      "XcodebuildPicker",
      "XcodebuildBuild",
      "XcodebuildBuildRun",
      "XcodebuildSelectScheme",
      "XcodebuildSelectDevice",
    },
  },
}
