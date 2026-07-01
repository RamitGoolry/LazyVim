local M = {}

local uv = vim.uv or vim.loop
local ns = "tiny-dfr"

local state = {
  pid = uv.os_getpid(),
  socket = nil,
  cwd = nil,
  mode = nil,
  file = nil,
  filetype = nil,
  dap = {
    active = false,
    state = "unknown",
    adapter = nil,
    session = nil,
    updated_at_ms = nil,
  },
  dapui = {
    available = false,
    visible = false,
  },
  neotest = {
    available = false,
    summary_visible = false,
    updated_at_ms = nil,
  },
  dbui = {
    available = false,
    visible = false,
    in_buffer = false,
    connections = {},
  },
}

local paths = nil
local server = nil
local clients = {}
local started = false

local function now_ms()
  if uv.gettimeofday then
    local seconds, microseconds = uv.gettimeofday()
    return (seconds * 1000) + math.floor((microseconds or 0) / 1000)
  end
  return os.time() * 1000
end

local function runtime_root()
  local dir = vim.env.TINY_DFR_RUNTIME_DIR
  if dir and dir ~= "" then
    return dir
  end
  dir = vim.env.XDG_RUNTIME_DIR
  if dir and dir ~= "" then
    return dir .. "/tiny-dfr"
  end
  local user = vim.env.USER or vim.env.LOGNAME or tostring(vim.fn.getuid())
  return "/tmp/tiny-dfr-" .. user
end

local function bridge_paths()
  if paths then
    return paths
  end

  local dir = runtime_root() .. "/nvim"
  local pid = tostring(state.pid)
  paths = {
    dir = dir,
    state = dir .. "/" .. pid .. ".json",
    socket = dir .. "/" .. pid .. ".sock",
  }
  state.socket = paths.socket
  return paths
end

local function json_encode(value)
  return vim.json.encode(value)
end

local function json_decode(value)
  return vim.json.decode(value)
end

local function atomic_write(path, content)
  local tmp = path .. ".tmp"
  local fd, err = uv.fs_open(tmp, "w", 384) -- 0600
  if not fd then
    return nil, err
  end

  local ok, write_err = uv.fs_write(fd, content, -1)
  uv.fs_close(fd)
  if not ok then
    pcall(uv.fs_unlink, tmp)
    return nil, write_err
  end

  local rename_ok, rename_err = uv.fs_rename(tmp, path)
  if not rename_ok then
    pcall(uv.fs_unlink, tmp)
    return nil, rename_err
  end
  return true
end

local function current_file()
  local name = vim.api.nvim_buf_get_name(0)
  if name == "" then
    return nil
  end
  return name
end

local function is_dapui_filetype(filetype)
  return filetype == "dap-repl" or filetype == "dapui_console" or filetype:match("^dapui_") ~= nil
end

local function window_with_filetype(predicate)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local ok, bufnr = pcall(vim.api.nvim_win_get_buf, win)
    if ok and vim.api.nvim_buf_is_valid(bufnr) then
      local filetype = vim.bo[bufnr].filetype or ""
      if predicate(filetype) then
        return true
      end
    end
  end
  return false
end

local function dapui_visible()
  return window_with_filetype(is_dapui_filetype)
end

local function neotest_summary_visible()
  return window_with_filetype(function(filetype)
    return filetype == "neotest-summary"
  end)
end

local function dbui_visible()
  return window_with_filetype(function(filetype)
    return filetype == "dbui"
  end)
end

local function dbui_in_buffer()
  local name = vim.api.nvim_buf_get_name(0)
  return name:match("^dbui://") ~= nil or vim.b.dbui_db_key_name ~= nil
end

local function dbui_connections()
  local ok, connections = pcall(vim.fn["db_ui#connections_list"])
  if not ok or type(connections) ~= "table" then
    return {}
  end
  local out = {}
  for _, conn in ipairs(connections) do
    local name = tostring(conn.name or "")
    local source = tostring(conn.source or "")
    table.insert(out, {
      name = name,
      source = source,
      key_name = name .. "_" .. source,
      is_connected = conn.is_connected == 1 or conn.is_connected == true,
    })
  end
  return out
end

local function refresh_editor_state()
  state.cwd = uv.cwd()
  state.mode = vim.api.nvim_get_mode().mode
  state.file = current_file()
  state.filetype = vim.bo.filetype
  state.dapui.available = package.loaded["dapui"] ~= nil or pcall(require, "dapui")
  state.dapui.visible = dapui_visible()
  state.neotest.available = package.loaded["neotest"] ~= nil or pcall(require, "neotest")
  state.neotest.summary_visible = neotest_summary_visible()
  state.dbui.available = vim.fn.exists(":DBUI") == 2 or vim.fn.exists("g:loaded_dbui") == 1
  state.dbui.visible = dbui_visible()
  state.dbui.in_buffer = dbui_in_buffer()
  state.dbui.connections = dbui_connections()
end

local function session_label(session)
  if not session or not session.config then
    return nil
  end
  return session.config.name or session.config.request
end

local function session_adapter(session)
  if not session or not session.config then
    return nil
  end
  return session.config.type
end

local function set_dap_state(active, dap_state, session)
  state.dap.active = active
  state.dap.state = dap_state or state.dap.state or "unknown"
  state.dap.adapter = session_adapter(session)
  state.dap.session = session_label(session)
  state.dap.updated_at_ms = now_ms()
end

local function refresh_dap_state()
  local ok, dap = pcall(require, "dap")
  if not ok then
    set_dap_state(false, "unavailable", nil)
    return
  end

  local session = nil
  local session_ok, session_or_err = pcall(dap.session)
  if session_ok then
    session = session_or_err
  end

  if session then
    if not state.dap.active then
      set_dap_state(true, "unknown", session)
    else
      state.dap.adapter = session_adapter(session)
      state.dap.session = session_label(session)
    end
  elseif state.dap.active then
    set_dap_state(false, "terminated", nil)
  else
    set_dap_state(false, "idle", nil)
  end
end

local function write_state()
  local p = bridge_paths()
  vim.fn.mkdir(p.dir, "p")
  refresh_editor_state()
  refresh_dap_state()

  local encoded = json_encode(state) .. "\n"
  local ok, err = atomic_write(p.state, encoded)
  if not ok then
    vim.schedule(function()
      vim.notify("Failed to write tiny-dfr nvim bridge state: " .. tostring(err), vim.log.levels.WARN, {
        title = "tiny-dfr bridge",
      })
    end)
  end
end

local function write_response(client, response)
  if not client or client:is_closing() then
    return
  end
  client:write(json_encode(response) .. "\n")
end

local actions = {}

local function require_module(name)
  local ok, mod = pcall(require, name)
  if not ok then
    error("module not available: " .. name)
  end
  return mod
end

actions["dap.continue"] = function()
  require_module("dap").continue()
end

actions["dap.pause"] = function()
  require_module("dap").pause()
end

actions["dap.step_over"] = function()
  require_module("dap").step_over()
end

actions["dap.step_into"] = function()
  require_module("dap").step_into()
end

actions["dap.step_out"] = function()
  require_module("dap").step_out()
end

actions["dap.restart_frame"] = function()
  local dap = require_module("dap")
  if type(dap.restart_frame) == "function" then
    dap.restart_frame()
  elseif type(dap.restart) == "function" then
    dap.restart()
  else
    error("nvim-dap has no restart_frame or restart action")
  end
end

actions["dap.terminate"] = function()
  require_module("dap").terminate()
end

actions["dap.toggle_breakpoint"] = function()
  require_module("dap").toggle_breakpoint()
end

actions["dap.repl_toggle"] = function()
  require_module("dap").repl.toggle()
end

actions["dapui.toggle"] = function()
  require_module("dapui").toggle()
end

actions["debug.open"] = function()
  local dapui = require_module("dapui")
  if type(dapui.open) == "function" then
    dapui.open()
  else
    dapui.toggle()
  end
end

actions["debug.close"] = function()
  local dapui = require_module("dapui")
  if type(dapui.close) == "function" then
    dapui.close()
  else
    dapui.toggle()
  end
end

actions["neotest.run_nearest"] = function()
  require_module("neotest").run.run()
  state.neotest.updated_at_ms = now_ms()
end

actions["neotest.run_file"] = function()
  require_module("neotest").run.run(vim.fn.expand("%"))
  state.neotest.updated_at_ms = now_ms()
end

actions["neotest.run_all"] = function()
  require_module("neotest").run.run(vim.uv.cwd())
  state.neotest.updated_at_ms = now_ms()
end

actions["neotest.debug_nearest"] = function()
  require_module("neotest").run.run({ strategy = "dap" })
  state.neotest.updated_at_ms = now_ms()
end

actions["neotest.stop"] = function()
  require_module("neotest").run.stop()
  state.neotest.updated_at_ms = now_ms()
end

actions["neotest.summary_toggle"] = function()
  require_module("neotest").summary.toggle()
end

actions["neotest.summary_open"] = function()
  local neotest = require_module("neotest")
  if type(neotest.summary.open) == "function" then
    neotest.summary.open()
  else
    neotest.summary.toggle()
  end
end

actions["neotest.summary_close"] = function()
  local neotest = require_module("neotest")
  if type(neotest.summary.close) == "function" then
    neotest.summary.close()
  else
    neotest.summary.toggle()
  end
end

actions["neotest.output_open"] = function()
  require_module("neotest").output.open({ enter = true, auto_close = true })
end

actions["neotest.output_panel_toggle"] = function()
  require_module("neotest").output_panel.toggle()
end

actions["dbui.open"] = function()
  vim.cmd("DBUI")
end

actions["dbui.close"] = function()
  vim.cmd("DBUIClose")
end

actions["dbui.toggle"] = function()
  vim.cmd("DBUIToggle")
end

actions["dbui.find_buffer"] = function()
  vim.cmd("DBUIFindBuffer")
end

actions["dbui.connect"] = function(msg)
  local key = msg.db_key_name
  if type(key) ~= "string" or key == "" then
    error("missing db_key_name")
  end
  local info = vim.fn["db_ui#get_conn_info"](key)
  if type(info) ~= "table" or not info.connected then
    error("failed to connect db: " .. key)
  end
  vim.cmd("enew")
  local name = key:gsub("[^%w_.-]", "_")
  vim.api.nvim_buf_set_name(0, "dbui://" .. name .. ".sql")
  vim.cmd("call db_ui#drawer#get().get_query().setup_buffer(db_ui#drawer#get().dbui.dbs[" .. vim.fn.string(key) .. "], {}, bufname('%'), 0)")
end

actions["dbui.last_query_info"] = function()
  vim.cmd("DBUILastQueryInfo")
end

actions["dbui.execute_query"] = function()
  local mode = vim.api.nvim_get_mode().mode
  if mode:match("^[vV\22]") then
    vim.cmd([[normal! \27]])
    vim.cmd([[normal! gv]])
  end
  vim.cmd([[execute "normal \\<Plug>(DBUI_ExecuteQuery)"]])
end

local function handle_message(client, line)
  local ok, msg = pcall(json_decode, line)
  if not ok or type(msg) ~= "table" then
    write_response(client, { id = nil, ok = false, error = "invalid JSON message" })
    return
  end

  local id = msg.id
  local action_name = msg.action
  if type(action_name) ~= "string" then
    write_response(client, { id = id, ok = false, error = "missing action" })
    return
  end

  local action = actions[action_name]
  if not action then
    write_response(client, { id = id, ok = false, error = "unknown action: " .. action_name })
    return
  end

  vim.schedule(function()
    local action_ok, err = pcall(action, msg)
    write_state()
    for _, delay in ipairs({ 50, 150, 300, 750 }) do
      vim.defer_fn(function()
        if started then
          write_state()
        end
      end, delay)
    end
    if action_ok then
      write_response(client, { id = id, ok = true })
    else
      write_response(client, { id = id, ok = false, error = tostring(err) })
    end
  end)
end

local function close_client(client)
  clients[client] = nil
  if client and not client:is_closing() then
    client:close()
  end
end

local function accept_client()
  local client = uv.new_pipe(false)
  local ok, err = pcall(function()
    server:accept(client)
  end)
  if not ok then
    if client and not client:is_closing() then
      client:close()
    end
    vim.schedule(function()
      vim.notify("tiny-dfr bridge accept failed: " .. tostring(err), vim.log.levels.WARN, {
        title = "tiny-dfr bridge",
      })
    end)
    return
  end

  clients[client] = true
  local buffer = ""
  client:read_start(function(read_err, chunk)
    if read_err then
      close_client(client)
      return
    end
    if not chunk then
      close_client(client)
      return
    end

    buffer = buffer .. chunk
    while true do
      local newline = buffer:find("\n", 1, true)
      if not newline then
        break
      end
      local line = buffer:sub(1, newline - 1)
      buffer = buffer:sub(newline + 1)
      if line ~= "" then
        handle_message(client, line)
      end
    end
  end)
end

local function start_socket()
  local p = bridge_paths()
  vim.fn.mkdir(p.dir, "p")
  pcall(uv.fs_unlink, p.socket)

  server = uv.new_pipe(false)
  local bind_ok, bind_err = server:bind(p.socket)
  if not bind_ok then
    server:close()
    server = nil
    error("failed to bind " .. p.socket .. ": " .. tostring(bind_err))
  end

  local listen_ok, listen_err = server:listen(16, function(err)
    if err then
      vim.schedule(function()
        vim.notify("tiny-dfr bridge listen failed: " .. tostring(err), vim.log.levels.WARN, {
          title = "tiny-dfr bridge",
        })
      end)
      return
    end
    accept_client()
  end)

  if not listen_ok then
    server:close()
    server = nil
    error("failed to listen on " .. p.socket .. ": " .. tostring(listen_err))
  end

  pcall(uv.fs_chmod, p.socket, 384) -- 0600
end

local function install_dap_listeners()
  local ok, dap = pcall(require, "dap")
  if not ok then
    return
  end

  dap.listeners.after.event_initialized = dap.listeners.after.event_initialized or {}
  dap.listeners.after.event_stopped = dap.listeners.after.event_stopped or {}
  dap.listeners.after.event_continued = dap.listeners.after.event_continued or {}
  dap.listeners.after.event_terminated = dap.listeners.after.event_terminated or {}
  dap.listeners.after.event_exited = dap.listeners.after.event_exited or {}

  dap.listeners.after.event_initialized[ns] = function(session)
    vim.schedule(function()
      set_dap_state(true, "initialized", session)
      write_state()
    end)
  end

  dap.listeners.after.event_stopped[ns] = function(session)
    vim.schedule(function()
      set_dap_state(true, "stopped", session)
      write_state()
    end)
  end

  dap.listeners.after.event_continued[ns] = function(session)
    vim.schedule(function()
      set_dap_state(true, "running", session)
      write_state()
    end)
  end

  dap.listeners.after.event_terminated[ns] = function()
    vim.schedule(function()
      set_dap_state(false, "terminated", nil)
      write_state()
    end)
  end

  dap.listeners.after.event_exited[ns] = function()
    vim.schedule(function()
      set_dap_state(false, "exited", nil)
      write_state()
    end)
  end
end

local function deferred_write_state()
  write_state()
  vim.defer_fn(function()
    if started then
      write_state()
    end
  end, 75)
end

local function install_autocmds()
  local group = vim.api.nvim_create_augroup("TinyDfrBridge", { clear = true })

  vim.api.nvim_create_autocmd({
    "BufEnter",
    "BufWinEnter",
    "BufWinLeave",
    "BufWritePost",
    "DirChanged",
    "FileType",
    "ModeChanged",
    "TabEnter",
    "VimResume",
    "WinClosed",
    "WinEnter",
  }, {
    group = group,
    callback = function()
      deferred_write_state()
    end,
  })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      M.stop()
    end,
  })
end

function M.setup()
  if started then
    return
  end
  started = true

  local ok, err = pcall(start_socket)
  if not ok then
    started = false
    vim.notify("Failed to start tiny-dfr nvim bridge: " .. tostring(err), vim.log.levels.WARN, {
      title = "tiny-dfr bridge",
    })
    return
  end

  install_dap_listeners()
  install_autocmds()
  write_state()
end

function M.stop()
  for client in pairs(clients) do
    close_client(client)
  end
  if server and not server:is_closing() then
    server:close()
  end
  server = nil
  if paths then
    pcall(uv.fs_unlink, paths.socket)
    pcall(uv.fs_unlink, paths.state)
  end
  started = false
end

function M.state()
  write_state()
  return vim.deepcopy(state)
end

function M.actions()
  local names = {}
  for name in pairs(actions) do
    table.insert(names, name)
  end
  table.sort(names)
  return names
end

return M
