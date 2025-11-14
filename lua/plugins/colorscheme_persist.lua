local persist_file = vim.fs.joinpath(vim.fn.stdpath("state"), "colorscheme.txt")
local persist_dir = vim.fn.fnamemodify(persist_file, ":h")

local function read_last_colorscheme()
  local ok, data = pcall(vim.fn.readfile, persist_file)
  if not ok or not data or not data[1] then
    return nil
  end
  local name = vim.trim(data[1])
  return name ~= "" and name or nil
end

local function write_last_colorscheme(name)
  if not name or name == "" then
    return
  end
  vim.fn.mkdir(persist_dir, "p")
  vim.fn.writefile({ name }, persist_file)
end

return {
  {
    "LazyVim/LazyVim",
    init = function()
      local group = vim.api.nvim_create_augroup("PersistColorscheme", { clear = true })
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = group,
        desc = "Persist the last selected colorscheme",
        callback = function()
          local name = vim.g.colors_name
          if name and name ~= "" then
            write_last_colorscheme(name)
          end
        end,
      })
    end,
    opts = function(_, opts)
      local last = read_last_colorscheme()
      if last then
        opts.colorscheme = last
      end
    end,
  },
}

