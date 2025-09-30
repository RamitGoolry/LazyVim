return {
  "marilari88/twoslash-queries.nvim",
  ft = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
  config = function()
    require("twoslash-queries").setup({
      multi_line = true,
      is_enabled = true,
      highlight = "Type",
    })
  end,
  init = function()
    local function attach_twoslash(client, bufnr)
      if client.name == "vtsls" or client.name == "ts_ls" or client.name == "tsserver" then
        require("twoslash-queries").attach(client, bufnr)
      end
    end

    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(args)
        local bufnr = args.buf
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if client then
          attach_twoslash(client, bufnr)
        end
      end,
    })
  end,
}
