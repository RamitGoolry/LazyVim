# Plan: Vendor `sidekick.nvim` and add Herdr attach backend

## Goal
Use a vendored copy of `folke/sidekick.nvim` inside this Neovim config so we can extend it locally, starting with a Herdr backend that attaches/sends to existing Herdr agents/panes without creating new panes.

## Current findings
- Current plugin spec: `lua/plugins/sidekick.lua` loads remote `folke/sidekick.nvim`.
- Installed upstream copy: `/home/ramit/.local/share/nvim/lazy/sidekick.nvim` at `208e1c5`.
- Sidekick only registers mux session backends from `sidekick.cli.session`: `tmux`, `zellij`, and `terminal`.
- Sidekick validates `opts.cli.mux.backend` against only `tmux|zellij`, so `herdr` must be added there if we want it as a first-class mux backend.
- Existing `backend = "tmux"` in `lua/plugins/sidekick.lua` appears to be a no-op for current Sidekick; the real setting is `cli.mux.backend`.
- Existing keymaps in `lua/config/keymaps.lua` pass `{ backend = "tmux" }` to `require("sidekick.cli").toggle()`, but current `filter_opts()` ignores `backend`, so those overrides are also likely no-ops.
- Herdr exposes useful CLI commands:
  - `herdr agent list`, `agent send`, `agent read`, `agent focus`, `agent attach`
  - `herdr pane list`, `pane send-text`, `pane send-keys`, `pane read`
  - Env from inside Herdr includes `HERDR_ENV=1`, `HERDR_PANE_ID`, `HERDR_SOCKET_PATH`.

## Constraints / decisions
- Local workaround first, not upstream PR yet.
- Initial Herdr integration should **attach to existing Herdr agents only**.
- Do **not** create/split new Herdr panes yet.
- Prefer a clean vendored plugin path over monkey-patching in config.

## Implementation approach

### 1. Vendor Sidekick
- Copy installed plugin from:
  - `/home/ramit/.local/share/nvim/lazy/sidekick.nvim`
- Into repo path, likely:
  - `vendor/sidekick.nvim/`
- Keep upstream metadata if useful (`.git` excluded unless we deliberately want nested repo history; simpler is plain vendored source).

### 2. Point Lazy at vendored plugin
Update `lua/plugins/sidekick.lua` from remote spec to local dir spec:

```lua
return {
  dir = vim.fn.stdpath("config") .. "/vendor/sidekick.nvim",
  name = "sidekick.nvim",
  opts = {
    ai = { provider = "claude" },
    nes = { enabled = false, auto_fetch = false },
    cli = {
      mux = {
        enabled = true,
        backend = "herdr",
      },
    },
  },
}
```

Alternative if `stdpath("config")` feels too magical: `dir = "/home/ramit/.config/nvim/vendor/sidekick.nvim"`.

### 3. Add a minimal Herdr session backend
Create vendored file:

- `vendor/sidekick.nvim/lua/sidekick/cli/session/herdr.lua`

Initial responsibilities:
- `sessions()` lists existing Herdr agents and/or panes.
- `send(text)` sends literal text to the selected target.
- `submit()` sends Enter.
- `dump()` reads recent output.
- `is_running()` checks the target still exists.
- `start()` should warn/return nil for now: attach-only backend.
- `attach()` can return nil for external attach, or eventually `herdr agent attach <target>` if Sidekick needs a visible terminal.

### 4. Register Herdr in Sidekick core
Patch vendored `vendor/sidekick.nvim/lua/sidekick/cli/session/init.lua`:

```lua
local session_backends = {
  tmux = "sidekick.cli.session.tmux",
  zellij = "sidekick.cli.session.zellij",
  herdr = "sidekick.cli.session.herdr",
}
```

Register if `vim.fn.executable("herdr") == 1`.

Patch vendored `vendor/sidekick.nvim/lua/sidekick/config.lua` validation:

```lua
M.validate("cli.mux.backend", { "tmux", "zellij", "herdr" })
```

### 5. Decide agent vs pane API for first version
Preferred first implementation: use `herdr agent ...` because the user's goal is existing Herdr agents.

Potential mapping:
- `sessions()` => parse `herdr agent list` JSON if available.
- `send(text)` => `herdr agent send <target> <text>`.
- `submit()` => likely send `\n` or use pane low-level send-keys if target exposes pane id.
- `dump()` => `herdr agent read <target> --source recent-unwrapped --lines <dump>`.

If `agent list --json` is unavailable or output shape is awkward, fallback to `pane list` plus `agent` fields.

### 6. Keymap cleanup
Update sidekick keymaps in `lua/config/keymaps.lua`:
- Remove no-op `{ backend = "tmux" }` from `toggle()` calls.
- Or replace with valid filters if Sidekick supports selecting by mux backend after our changes.

### 7. Validation
Manual checks in Neovim:
- `:Lazy` shows `sidekick.nvim` from local `vendor/sidekick.nvim`.
- `:checkhealth sidekick` if available.
- `:Sidekick` command still exists.
- Existing Sidekick prompts still render.
- Running Herdr agent appears in Sidekick CLI selection.
- Sending prompt from Sidekick reaches existing Herdr Claude/Pi pane.
- Dump/scrollback works enough for context/status.

## Git hygiene note
Repo currently has a dirty `lazy-lock.json` with many plugin update changes unrelated to vendoring. Before implementing, decide whether to keep, revert, or separately commit those lockfile updates.
