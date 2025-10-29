local lib = require("neotest.lib")
local Tree = require("neotest.types").Tree

local function default_is_test_file(file_path)
  return vim.endswith(file_path, ".hurl")
end

local function default_root(dir)
  return lib.files.match_root_pattern("hurl.toml", ".git")(dir)
end

local function resolve_command(command, position)
  if type(command) == "function" then
    return resolve_command(command(position), position)
  end
  if type(command) == "string" then
    return { command }
  end
  if type(command) == "table" then
    return vim.deepcopy(command)
  end
  return { "hurl" }
end

local function resolve_args(args, position)
  if type(args) == "function" then
    return resolve_args(args(position), position)
  end
  if type(args) == "table" then
    return vim.deepcopy(args)
  end
  if type(args) == "string" then
    return { args }
  end
  return {}
end

local function resolve_env(env, position)
  if type(env) == "function" then
    return resolve_env(env(position), position)
  end
  if type(env) == "table" then
    return vim.deepcopy(env)
  end
  return nil
end

local function collect_test_nodes(node, acc, seen)
  acc = acc or {}
  seen = seen or {}
  local pos = node:data()
  if seen[pos.id] then
    return acc
  end
  if pos.type == "test" then
    seen[pos.id] = true
    table.insert(acc, node)
    return acc
  end

  if pos.type == "file" then
    local added_child = false
    for _, child in ipairs(node:children()) do
      local child_pos = child:data()
      if child_pos.type == "test" then
        collect_test_nodes(child, acc, seen)
        added_child = true
      end
    end
    if not added_child then
      seen[pos.id] = true
      table.insert(acc, node)
    end
    return acc
  end

  for _, child in ipairs(node:children()) do
    collect_test_nodes(child, acc, seen)
  end
  return acc
end

local function display_name_from_file(path)
  local ok, lines = pcall(vim.fn.readfile, path, "", 1)
  if not ok or not lines or #lines == 0 then
    return nil
  end

  local first_line = vim.trim(lines[1] or "")
  if first_line == "" then
    return nil
  end

  local comment = first_line:match("^%s*#+%s*(.+)$")
  if comment and comment ~= "" then
    return vim.trim(comment)
  end
end

local function make_file_tree(path)
  local file_name = vim.fn.fnamemodify(path, ":t")
  local test_name = display_name_from_file(path) or file_name
  return Tree.from_list({
    {
      type = "file",
      id = path,
      name = file_name,
      path = path,
      range = { 0, 0, 0, 0 },
    },
    {
      type = "test",
      id = ("%s::file"):format(path),
      name = test_name,
      path = path,
      range = { 0, 0, 0, 0 },
      parent = path,
    },
  }, function(pos)
    return pos.id
  end)
end

local function create_adapter(opts)
  opts = vim.tbl_deep_extend("force", {
    command = "hurl",
    args = {},
    env = {},
    root = default_root,
    is_test_file = default_is_test_file,
    filter_dir = function()
      return true
    end,
  }, opts or {})

  ---@type neotest.Adapter
  local adapter = {
    name = "neotest-hurl",
  }

  function adapter.root(path)
    if type(opts.root) == "function" then
      return opts.root(path)
    end
    return opts.root
  end

  function adapter.is_test_file(file_path)
    return opts.is_test_file(file_path)
  end

  adapter.filter_dir = opts.filter_dir

  function adapter.discover_positions(path)
    if not adapter.is_test_file(path) then
      return
    end
    return make_file_tree(path)
  end

  ---@param args neotest.RunArgs
  ---@return neotest.RunSpec[] | neotest.RunSpec | nil
  function adapter.build_spec(args)
    local nodes = collect_test_nodes(args.tree)
    if #nodes == 0 then
      return nil
    end

    local specs = {}
    for _, node in ipairs(nodes) do
      local pos = node:data()
      local file_path = vim.fn.fnamemodify(pos.path, ":p")
      local file_dir = vim.fn.fnamemodify(file_path, ":h")

      local command = resolve_command(opts.command, pos)
      local cmd_args = resolve_args(opts.args, pos)
      local extra_args = resolve_args(args.extra_args, pos)
      vim.list_extend(command, cmd_args)
      vim.list_extend(command, extra_args)
      table.insert(command, file_path)

      local cwd
      local root = adapter.root(file_dir)
      if type(root) == "string" and root ~= "" then
        cwd = root
      else
        cwd = file_dir
      end

      local spec_env = resolve_env(opts.env, pos)
      if spec_env and vim.tbl_isempty(spec_env) then
        spec_env = nil
      end

      local parent = node:parent()

      table.insert(specs, {
        command = command,
        cwd = cwd,
        env = spec_env,
        context = {
          test_id = pos.id,
          parent_id = parent and parent:data().id or nil,
          file_path = file_path,
        },
      })
    end

    return specs
  end

  ---@param spec neotest.RunSpec
  ---@param result neotest.StrategyResult
  ---@return table<string, neotest.Result>
  function adapter.results(spec, result)
    local output = result.output
    result.output = nil
    local status = result.code == 0 and "passed" or "failed"
    local results = {
      [spec.context.test_id] = {
        status = status,
        output = output,
        short = ("%s %s"):format(vim.fn.fnamemodify(spec.context.file_path, ":t"), status),
      },
    }
    if spec.context.parent_id then
      results[spec.context.parent_id] = {
        status = status,
        output = output,
      }
    end
    return results
  end

  return adapter
end

local HurlNeotestAdapter = create_adapter()

setmetatable(HurlNeotestAdapter, {
  __call = function(_, opts)
    return create_adapter(opts)
  end,
})

return HurlNeotestAdapter
