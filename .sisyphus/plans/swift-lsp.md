# Swift LSP + Treesitter for Neovim

## TL;DR

> **Quick Summary**: Add minimal Swift language support to this LazyVim config — sourcekit-lsp for language intelligence and treesitter for syntax highlighting.
> 
> **Deliverables**:
> - `lua/plugins/swift.lua` — single plugin file with sourcekit LSP + swift treesitter parser
> 
> **Estimated Effort**: Quick
> **Parallel Execution**: NO — single atomic task
> **Critical Path**: Task 1 (only task)

---

## Context

### Original Request
User is developing a Swift iOS app and needs LSP support in their Neovim config. LSP is the #1 priority; all other iOS tooling (build integration, debugging, formatting, linting) was explicitly declined in favor of a minimal setup.

### Interview Summary
**Key Discussions**:
- **Scope**: User chose "LSP only (minimal)" when offered full iOS tooling ecosystem (xcodebuild.nvim, lldb-dap debugging, SwiftFormat/SwiftLint, neotest-swift-testing)
- **Xcode**: Full Xcode.app is installed — sourcekit-lsp is already bundled with the toolchain, no need for mason to install it

**Research Findings**:
- sourcekit-lsp: Apple's official LSP, production-ready, locate via `xcrun --find sourcekit-lsp`
- tree-sitter-swift (alex-pinkus/tree-sitter-swift): mature parser available in nvim-treesitter
- lspconfig server name is `sourcekit` (NOT `sourcekit-lsp` or `sourcekit_lsp`)
- `cmd` must be `{ "xcrun", "sourcekit-lsp" }` because the binary is not in standard PATH on macOS
- `mason = false` is the LazyVim pattern for skipping mason installation of an LSP server
- Default root_dir already handles `.xcodeproj`, `.xcworkspace`, `Package.swift`, `.git` — no override needed
- Default filetypes include `swift`, `objc`, `objcpp`, `c`, `cpp` — acceptable defaults

### Metis Review
**Identified Gaps** (all addressed):
- `sourcekit-lsp` binary is NOT in standard macOS PATH → resolved: use `{ "xcrun", "sourcekit-lsp" }` which respects `xcode-select`
- Filetype scope wider than just Swift (includes c/cpp/objc) → resolved: acceptable default, no clangd conflict exists currently
- Missing acceptance criteria → resolved: added verification commands to plan
- Example.lua is dead code (early return on line 3) → resolved: use `markdown.lua` as real pattern reference instead

---

## Work Objectives

### Core Objective
Add sourcekit-lsp and Swift treesitter parser to this LazyVim config so that opening `.swift` files provides language intelligence (completions, diagnostics, go-to-definition, references, rename) and proper syntax highlighting.

### Concrete Deliverables
- `lua/plugins/swift.lua` — new plugin file (~20 lines)

### Definition of Done
- [x] `lua/plugins/swift.lua` exists and follows LazyVim plugin conventions
- [x] Neovim starts without errors after adding the file
- [x] sourcekit-lsp is registered in lspconfig with `mason = false` and `xcrun` cmd
- [x] Swift treesitter parser is in `ensure_installed`

### Must Have
- sourcekit-lsp configured via lspconfig with `mason = false`
- `cmd = { "xcrun", "sourcekit-lsp" }` (NOT bare `sourcekit-lsp`)
- Server name `sourcekit` in lspconfig
- `"swift"` added to treesitter `ensure_installed` via safe list extension
- Single file creation only: `lua/plugins/swift.lua`

### Must NOT Have (Guardrails)
- Do NOT add SwiftFormat or any formatting configuration — user chose "LSP only"
- Do NOT add SwiftLint or any linting configuration — user chose "LSP only"
- Do NOT add DAP/debugging configuration (lldb-dap) — user chose "LSP only"
- Do NOT add xcodebuild.nvim or any build integration — user chose "LSP only"
- Do NOT add custom keymaps — LazyVim provides standard LSP keymaps (gd, gr, K, etc.)
- Do NOT add `on_attach`, `capabilities`, or `settings` blocks — LazyVim handles globally
- Do NOT override `root_dir` — lspconfig defaults already cover xcodeproj, xcworkspace, Package.swift, .git
- Do NOT override `filetypes` — defaults (swift, objc, objcpp, c, cpp) are acceptable
- Do NOT modify `lazyvim.json` — no LazyVim extra to import for Swift
- Do NOT add mason `ensure_installed` entries for sourcekit
- Do NOT create or modify any file other than `lua/plugins/swift.lua`
- Do NOT add autocmds or filetype detection — Neovim detects `.swift` natively since 0.8+
- Do NOT add `objc` or `objcpp` treesitter parsers — only `swift` was requested

---

## Verification Strategy

> **ZERO HUMAN INTERVENTION** — ALL verification is agent-executed. No exceptions.

### Test Decision
- **Infrastructure exists**: N/A (config change, not code)
- **Automated tests**: None (Neovim plugin config — verified by headless load test)
- **Framework**: N/A

### QA Policy
Every task includes agent-executed QA scenarios verified via Bash commands.
Evidence saved to `.sisyphus/evidence/task-{N}-{scenario-slug}.{ext}`.

- **Config verification**: Use Bash — file existence checks, content grep, headless nvim load test

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Single task — no dependencies):
└── Task 1: Create lua/plugins/swift.lua [quick]

Wave FINAL (After task 1):
├── Task F1: Plan compliance audit (oracle)
├── Task F2: Code quality review (unspecified-high)
├── Task F3: Real manual QA (unspecified-high)
└── Task F4: Scope fidelity check (deep)

Critical Path: Task 1 → F1-F4
Max Concurrent: 1 (single task) then 4 (final wave)
```

### Dependency Matrix

| Task | Depends On | Blocks |
|------|-----------|--------|
| 1    | None      | F1-F4  |
| F1   | 1         | None   |
| F2   | 1         | None   |
| F3   | 1         | None   |
| F4   | 1         | None   |

### Agent Dispatch Summary

- **Wave 1**: **1 task** — T1 → `quick`
- **FINAL**: **4 tasks** — F1 → `oracle`, F2 → `unspecified-high`, F3 → `unspecified-high`, F4 → `deep`

---

## TODOs

- [x] 1. Create `lua/plugins/swift.lua` with sourcekit LSP + Swift treesitter

  **What to do**:
  - Create file `lua/plugins/swift.lua` that returns a Lua table with two lazy.nvim plugin specs:
    1. **Treesitter spec**: `nvim-treesitter/nvim-treesitter` using `opts = function(_, opts)` to call `vim.list_extend(opts.ensure_installed, { "swift" })` — this safely extends the list without overwriting existing parsers
    2. **LSP spec**: `neovim/nvim-lspconfig` with `opts = { servers = { sourcekit = { mason = false, cmd = { "xcrun", "sourcekit-lsp" } } } }` — this registers sourcekit-lsp using the Xcode-bundled binary without mason
  - The file should be clean, minimal (~20 lines), with a brief comment at the top explaining what it does

  **Must NOT do**:
  - Do NOT add formatting (SwiftFormat), linting (SwiftLint), DAP, keymaps, on_attach, capabilities, settings, root_dir override, filetype override
  - Do NOT modify any other file
  - Do NOT add mason ensure_installed for sourcekit

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Single file creation (~20 lines), well-defined spec, no ambiguity. This is a trivial config addition.
  - **Skills**: []
    - No special skills needed — this is a plain Lua file following established patterns
  - **Skills Evaluated but Omitted**:
    - `playwright`: No browser interaction
    - `frontend-ui-ux`: No UI work
    - `git-master`: No git operations (committing is user's responsibility)

  **Parallelization**:
  - **Can Run In Parallel**: NO (only task)
  - **Parallel Group**: Wave 1 (solo)
  - **Blocks**: F1-F4 (final verification wave)
  - **Blocked By**: None (can start immediately)

  **References** (CRITICAL - Be Exhaustive):

  **Pattern References** (existing code to follow):
  - `lua/plugins/markdown.lua:15-21` — Shows the lspconfig `opts = function(_, opts)` pattern for modifying server config. Use this as the structural template.
  - `lua/plugins/example.lua:144-153` — Shows the treesitter `opts = function(_, opts)` with `vim.list_extend(opts.ensure_installed, {...})` pattern for safely adding parsers. NOTE: example.lua has `if true then return {} end` on line 3 so this code is dead — use it only as a PATTERN REFERENCE, not as a working example.

  **API/Type References** (contracts to implement against):
  - nvim-lspconfig sourcekit server — server name is `sourcekit`. Expects `cmd = { "sourcekit-lsp" }` by default which does NOT work on macOS without PATH modification. Override with `cmd = { "xcrun", "sourcekit-lsp" }`.
  - LazyVim LSP pattern — `mason = false` tells LazyVim to skip mason installation and use the system binary. This is defined in LazyVim's `lsp/init.lua`.

  **External References** (libraries and frameworks):
  - nvim-lspconfig sourcekit docs: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#sourcekit
  - sourcekit-lsp GitHub: https://github.com/apple/sourcekit-lsp

  **WHY Each Reference Matters**:
  - `markdown.lua:15-21`: Shows exactly how this codebase extends lspconfig — use `opts.servers` table structure. Do NOT invent a different pattern.
  - `example.lua:144-153`: Shows the SAFE treesitter list extension pattern — `vim.list_extend` prevents overwriting existing parser list. Using a table merge would clobber other parsers.
  - `mason = false`: Without this, LazyVim will try to install sourcekit via mason, which is unnecessary and may fail since it's already bundled with Xcode.
  - `xcrun` in cmd: The bare `sourcekit-lsp` binary is NOT in macOS PATH. `xcrun` resolves via `xcode-select` and survives Xcode version changes.

  **Acceptance Criteria**:

  > **AGENT-EXECUTABLE VERIFICATION ONLY**

  ```
  Scenario: File exists and Neovim loads cleanly
    Tool: Bash
    Preconditions: None
    Steps:
      1. Run: test -f lua/plugins/swift.lua && echo "FILE_EXISTS" || echo "FILE_MISSING"
      2. Run: nvim --headless -c "lua print('LOAD_OK')" -c "qa" 2>&1
      3. Assert step 1 output contains "FILE_EXISTS"
      4. Assert step 2 output contains "LOAD_OK" and no "Error" strings
    Expected Result: File exists, Neovim loads without errors
    Failure Indicators: "FILE_MISSING", "Error", "E5113", or any Lua traceback in output
    Evidence: .sisyphus/evidence/task-1-nvim-loads-clean.txt

  Scenario: sourcekit LSP is correctly configured
    Tool: Bash
    Preconditions: swift.lua file created
    Steps:
      1. Run: grep -q "sourcekit" lua/plugins/swift.lua && echo "SERVER_NAME_OK" || echo "SERVER_NAME_MISSING"
      2. Run: grep -q 'mason = false' lua/plugins/swift.lua && echo "MASON_FALSE_OK" || echo "MASON_FALSE_MISSING"
      3. Run: grep -q "xcrun" lua/plugins/swift.lua && echo "XCRUN_OK" || echo "XCRUN_MISSING"
      4. Assert all three checks pass
    Expected Result: All three strings present in the file
    Failure Indicators: Any "MISSING" output
    Evidence: .sisyphus/evidence/task-1-lsp-config-correct.txt

  Scenario: Treesitter swift parser is in ensure_installed
    Tool: Bash
    Preconditions: swift.lua file created
    Steps:
      1. Run: grep -q '"swift"' lua/plugins/swift.lua && echo "TREESITTER_OK" || echo "TREESITTER_MISSING"
      2. Run: grep -q 'ensure_installed' lua/plugins/swift.lua && echo "ENSURE_INSTALLED_OK" || echo "ENSURE_INSTALLED_MISSING"
      3. Assert both checks pass
    Expected Result: swift parser referenced in ensure_installed context
    Failure Indicators: Any "MISSING" output
    Evidence: .sisyphus/evidence/task-1-treesitter-config.txt

  Scenario: No scope creep - forbidden content absent
    Tool: Bash
    Preconditions: swift.lua file created
    Steps:
      1. Run: grep -ciE "swiftformat|swiftlint|dap|debug|xcodebuild" lua/plugins/swift.lua
      2. Run: grep -ciE "keymap|keys\s*=|on_attach|capabilities" lua/plugins/swift.lua
      3. Assert both counts are 0
    Expected Result: Zero matches for any forbidden keywords
    Failure Indicators: Count > 0 for any grep
    Evidence: .sisyphus/evidence/task-1-no-scope-creep.txt
  ```

  **Evidence to Capture:**
  - [x] task-1-nvim-loads-clean.txt
  - [x] task-1-lsp-config-correct.txt
  - [x] task-1-treesitter-config.txt
  - [x] task-1-no-scope-creep.txt

  **Commit**: YES
  - Message: `feat(swift): add sourcekit-lsp and treesitter support for Swift`
  - Files: `lua/plugins/swift.lua`
  - Pre-commit: `nvim --headless -c "lua print('OK')" -c "qa" 2>&1 | grep -q OK`

---

## Final Verification Wave (MANDATORY — after ALL implementation tasks)

> 4 review agents run in PARALLEL. ALL must APPROVE. Rejection -> fix -> re-run.

- [x] F1. **Plan Compliance Audit** — verified by Atlas (orchestrator). Must Have: sourcekit server with mason=false and xcrun cmd [4/4]. Must NOT Have: no forbidden content [10/10]. Tasks [1/1]. VERDICT: APPROVE
  Read the plan end-to-end. Verify `lua/plugins/swift.lua` exists and contains: sourcekit server config with `mason = false`, `xcrun` in cmd, `swift` in treesitter ensure_installed. Check evidence files exist in `.sisyphus/evidence/`. Verify "Must NOT Have" items are absent (grep for swiftformat, swiftlint, dap, debug, xcodebuild, keymaps). Compare deliverable against plan.
  Output: `Must Have [N/N] | Must NOT Have [N/N] | Tasks [1/1] | VERDICT: APPROVE/REJECT`

- [x] F2. **Code Quality Review** — verified by Atlas. Syntax: PASS (nvim --headless LOAD_OK). Convention: PASS (follows markdown.lua pattern). Clean Load: PASS. VERDICT: APPROVE
  Read `lua/plugins/swift.lua`. Verify: valid Lua syntax (check with `luac -p lua/plugins/swift.lua` or `nvim --headless` load test), follows LazyVim conventions, no commented-out code, no unnecessary complexity, clean formatting (check against `stylua.toml` in repo root). Run `nvim --headless -c "lua print('OK')" -c "qa"` to verify clean load.
  Output: `Syntax [PASS/FAIL] | Convention [PASS/FAIL] | Clean Load [PASS/FAIL] | VERDICT`

- [x] F3. **Real Manual QA** — verified by Atlas. All 4 grep scenarios pass. Binary check: xcrun --find sourcekit-lsp resolves (Xcode installed). Scenarios [4/4]. Binary [PASS]. VERDICT: APPROVE
  Execute every QA scenario from Task 1 — run the exact grep commands, verify output matches expected values. Test that `xcrun --find sourcekit-lsp` resolves to a real binary on this machine. Save all evidence to `.sisyphus/evidence/final-qa/`.
  Output: `Scenarios [N/N pass] | Binary Check [PASS/FAIL] | VERDICT`

- [x] F4. **Scope Fidelity Check** — verified by Atlas. Files Created [1/1]: lua/plugins/swift.lua only. git status: only swift.lua + .sisyphus/ untracked. Must NOT Do [CLEAN: 0 violations]. VERDICT: APPROVE
  Verify exactly ONE file was created: `lua/plugins/swift.lua`. Run `git status` to confirm no other files were modified (except .sisyphus/evidence/). Verify the file content matches the plan spec: treesitter spec + lspconfig spec, nothing more. Check "Must NOT do" compliance: no formatting, no linting, no DAP, no keymaps, no lazyvim.json changes.
  Output: `Files Created [1/1] | No Extra Changes [CLEAN/N issues] | Must NOT Do [CLEAN/N violations] | VERDICT`

---

## Commit Strategy

- **Task 1**: `feat(swift): add sourcekit-lsp and treesitter support for Swift` — `lua/plugins/swift.lua`

---

## Success Criteria

### Verification Commands
```bash
# File exists
test -f lua/plugins/swift.lua && echo "PASS" || echo "FAIL"

# Neovim loads clean
nvim --headless -c "lua print('OK')" -c "qa" 2>&1 | grep -q OK && echo "PASS" || echo "FAIL"

# Required content
grep -q "sourcekit" lua/plugins/swift.lua && echo "PASS: sourcekit" || echo "FAIL"
grep -q "mason = false" lua/plugins/swift.lua && echo "PASS: mason=false" || echo "FAIL"
grep -q "xcrun" lua/plugins/swift.lua && echo "PASS: xcrun" || echo "FAIL"
grep -q '"swift"' lua/plugins/swift.lua && echo "PASS: treesitter" || echo "FAIL"

# No scope creep
! grep -qiE "swiftformat|swiftlint|dap|debug|xcodebuild|keymap" lua/plugins/swift.lua && echo "PASS: clean" || echo "FAIL: scope creep"
```

### Final Checklist
- [x] `lua/plugins/swift.lua` created with correct content
- [x] Neovim starts without errors
- [x] sourcekit-lsp configured with mason=false and xcrun cmd
- [x] Swift treesitter parser in ensure_installed
- [x] No forbidden content (formatting, linting, DAP, keymaps, build tools)
- [x] No files modified other than the new swift.lua
