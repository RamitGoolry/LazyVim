
## [2026-03-06] Task 1: Create swift.lua

### Key Observations
- **vim.list_extend pattern confirmed**: Using `vim.list_extend(opts.ensure_installed, { "swift" })` safely appends to existing treesitter parsers without overwriting. This is the correct pattern for LazyVim plugin specs.
- **sourcekit-lsp via xcrun**: The `cmd = { "xcrun", "sourcekit-lsp" }` pattern correctly resolves the Xcode-bundled binary. `xcrun` is the proper way to invoke Xcode tools that survive version changes.
- **mason = false is critical**: Without this flag, LazyVim would attempt to install sourcekit via mason, which would fail since the binary is bundled with Xcode, not available on npm/pip/mason.
- **Server name is "sourcekit"**: Not `sourcekit-lsp` or `sourcekit_lsp`. This is the lspconfig server identifier.

### Patterns Confirmed
- LazyVim plugin files return a table of lazy.nvim specs
- Each spec is a table with plugin name and configuration
- `opts` can be a function `function(_, opts)` for merging, or a plain table for direct config
- For sourcekit, plain table `opts = { servers = { ... } }` works fine since we're not merging with existing opts

### Scope Boundaries
- LSP + Treesitter only (no formatters, linters, DAP, keymaps, or build integration)
- Minimal configuration: only what's needed for sourcekit-lsp to work
- Relies on LazyVim's global LSP setup for capabilities, on_attach, etc.

### File Verification
- Neovim loads headlessly without errors
- All required keywords present and correct
- No forbidden keywords (swiftformat, swiftlint, dap, debug, xcodebuild, keymap, on_attach, capabilities)
- File is clean, minimal, ~22 lines with comments
