local Config = require("sidekick.config")
local Util = require("sidekick.util")

---@class sidekick.cli.muxer.Herdr: sidekick.cli.Session
---@field herdr_agent string
---@field herdr_agent_status string?
---@field herdr_pane_id string
---@field herdr_terminal_id string
local M = {}
M.__index = M
M.priority = 10
M.external = true

local function decode(stdout)
  if not stdout or stdout == "" then
    return
  end
  local ok, decoded = pcall(vim.json.decode, stdout)
  if ok then
    return decoded
  end
end

---@param cmd string[]
---@param opts? vim.SystemOpts|{notify?:boolean}
local function exec_json(cmd, opts)
  local _, stdout = Util.exec(cmd, opts)
  return decode(stdout)
end

---@param agent table
---@return string?
local function target(agent)
  return agent.terminal_id or agent.pane_id
end

---@param workspace table
local function workspace_name(workspace)
  return workspace.label or workspace.name or workspace.custom_name or workspace.workspace_id
end

---@param tab table
local function tab_name(tab)
  return tab.label or tab.name or tab.custom_name or tab.tab_id
end

local function labels()
  local workspace_labels = {} ---@type table<string,string>
  local tab_labels = {} ---@type table<string,string>

  local workspaces = exec_json({ "herdr", "workspace", "list" }, { notify = false })
  for _, workspace in ipairs(workspaces and workspaces.result and workspaces.result.workspaces or {}) do
    if workspace.workspace_id then
      workspace_labels[workspace.workspace_id] = workspace_name(workspace)
    end
  end

  local tabs = exec_json({ "herdr", "tab", "list" }, { notify = false })
  for _, tab in ipairs(tabs and tabs.result and tabs.result.tabs or {}) do
    if tab.tab_id then
      local name = tab_name(tab)
      local workspace = workspace_labels[tab.workspace_id]
      tab_labels[tab.tab_id] = name
    end
  end

  return workspace_labels, tab_labels
end

function M:init()
  self.external = true
  self.priority = 10
end

---@return sidekick.cli.terminal.Cmd?
function M:start()
  Util.warn({
    "Herdr support is attach-only for now.",
    "Start the agent in Herdr first, then select the running Herdr agent from Sidekick.",
  })
end

---@return sidekick.cli.terminal.Cmd?
function M:attach()
  -- Attach in Sidekick means: remember this external Herdr agent as the target for
  -- Sidekick send/read operations. We intentionally do not open a terminal or
  -- create/split panes yet.
end

function M:is_running()
  local id = self.herdr_terminal_id or self.herdr_pane_id
  if not id then
    return false
  end

  local decoded = exec_json({ "herdr", "agent", "get", id }, { notify = false })
  return decoded and decoded.result ~= nil
end

---@return sidekick.cli.session.State[]
function M.sessions()
  local decoded = exec_json({ "herdr", "agent", "list" }, { notify = false })
  local agents = decoded and decoded.result and decoded.result.agents or {}
  local ret = {} ---@type sidekick.cli.session.State[]
  local tools = Config.tools()
  local workspace_labels, tab_labels = labels()

  for _, agent in ipairs(agents) do
    local name = agent.agent
    local tool = name and tools[name]
    local id = target(agent)

    if tool and id then
      ret[#ret + 1] = {
        id = "herdr " .. id,
        cwd = agent.foreground_cwd or agent.cwd or vim.fn.getcwd(0),
        tool = tool,
        external = true,
        herdr_agent = name,
        herdr_agent_status = agent.agent_status,
        herdr_pane_id = agent.pane_id,
        herdr_terminal_id = agent.terminal_id,
        mux_session = tab_labels[agent.tab_id] or workspace_labels[agent.workspace_id] or name,
      }
    end
  end

  return ret
end

---@param text string
function M:send(text)
  local id = self.herdr_terminal_id or self.herdr_pane_id
  if not id then
    Util.error("Herdr session has no terminal or pane id")
    return
  end

  Util.exec({ "herdr", "agent", "send", id, text })
end

function M:submit()
  if not self.herdr_pane_id then
    Util.error("Herdr session has no pane id")
    return
  end

  Util.exec({ "herdr", "pane", "send-keys", self.herdr_pane_id, "Enter" })
end

function M:dump()
  local id = self.herdr_terminal_id or self.herdr_pane_id
  if not id then
    return
  end

  local lines = tostring(Config.cli.mux.dump or 2000)
  local _, stdout = Util.exec({ "herdr", "agent", "read", id, "--source", "recent-unwrapped", "--lines", lines }, {
    notify = false,
  })
  return stdout
end

return M
