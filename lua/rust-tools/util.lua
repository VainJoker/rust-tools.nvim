local M = {}

P = function (v)
  print(vim.inspect(v))
  return v
end

function M.is_windows()
  local sysname = vim.loop.os_uname().sysname
  return sysname == "Windows" or sysname == "Windows_NT"
end

function M.lsp_buf_request(bufnr,method, params, handler)
  vim.lsp.buf_request(bufnr, method, params, handler)
end

function M.is_nushell()
    local shell = vim.loop.os_getenv("SHELL")
    local nu = "nu"
    -- Check if $SHELL ends in "nu"
    return shell:sub(-string.len(nu)) == nu
end

function M.delete_buf(bufnr)
  if bufnr ~= nil and vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end
end

function M.close_win(winnr)
  if winnr ~= nil and vim.api.nvim_win_is_valid(winnr) then
    vim.api.nvim_win_close(winnr, true)
  end
end

function M.split(bufnr)
  -- local cmd = config.vertical_split and "vsplit" or "split"
  --
  vim.cmd("split")
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, bufnr)
end

function M.resize(amount)
  -- local cmd = config.split_vertical and "vertical resize " or "resize"
  -- cmd = cmd .. amount

  vim.cmd("resize" .. amount)
end

return M
