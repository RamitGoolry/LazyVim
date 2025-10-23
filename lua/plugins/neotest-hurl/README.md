# neotest-hurl

This is a lightweight [neotest](https://github.com/nvim-neotest/neotest) adapter that knows how to run [Hurl](https://github.com/Orange-OpenSource/hurl) integration tests.

## Features

- Detects `.hurl` files and exposes a single test per file so they can be run via neotest.
- Runs each requested test file individually (`hurl <file>`), so failures are attributed to the correct buffer.
- Supports passing extra CLI arguments from neotest and respects per-project roots.

## Configuration

The adapter is registered in `lua/plugins/test.lua`:

```lua
local neotest_hurl = require("neotest-hurl")

require("neotest").setup({
  adapters = {
    neotest_hurl({
      -- command = { "hurl", "--fail-at-end" },
      -- args = { "--color" },
      -- env = { HURL_VARIABLE = "value" },
    }),
  },
})
```

Options:

- `command`: string, list, or function returning the executable to invoke (default: `"hurl"`).
- `args`: list or function returning extra arguments passed before the file path.
- `env`: table or function returning environment variables.
- `is_test_file`: predicate for recognizing test files (default: `.hurl` suffix).
- `root`: string or function used to determine the working directory (defaults to `hurl.toml` or `.git`).
- `filter_dir`: directory filter used by neotest when discovering tests.

With the adapter in place you can use the standard neotest commands (`:NeotestRun`, neotest keymaps, etc.) to execute your Hurl suites.
