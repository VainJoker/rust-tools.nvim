local util = require "rust-tools.util"
local M = {}

function M.get_dimensions()
  local cl = vim.o.columns
  local ln = vim.o.lines

  local dimensions = {
    height = 0.8,
    width = 0.8,
    x = 0.5,
    y = 0.5,
  }

  local width = math.ceil(cl * dimensions.width)
  local height = math.ceil(ln * dimensions.height - 4)
  local col = math.ceil((cl - width) * dimensions.x)
  local row = math.ceil((ln - height) * dimensions.y - 1)

  return {
    border = 'rounded',
    relative = 'editor',
    style = 'minimal',
    width = width,
    height = height,
    row = row,
    col = col,
  }
end

function M.run_command(cmd)
  local output = vim.fn.system(cmd)
  local lines = vim.fn.split(output, "\n")
  return lines
end

function M.ui(lines,buftype,filetype)
  local config = M.get_dimensions()

  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, config)

  vim.api.nvim_set_option_value('buftype',buftype, {})
  vim.api.nvim_set_option_value('filetype',filetype,{})

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_keymap(buf, 'n', 'q', '<cmd>q<CR>', { noremap = true, silent = true })

  vim.api.nvim_command("autocmd WinClosed <buffer=" .. buf .. "> ++once lua vim.api.nvim_win_close(" .. win .. ", true)")
end

function M.make_command_from_args(command, args)
  local ret = command .. " "

  for _, value in ipairs(args) do
    ret = ret .. value .. " "
  end

  return ret
end

function M.chain_commands(commands)
  local separator = util.is_windows() and " | "
    or util.is_nushell() and ";"
    or " && "
  local ret = ""

  for i, value in ipairs(commands) do
    local is_last = i == #commands
    ret = ret .. value

    if not is_last then
      ret = ret .. separator
    end
  end

  return ret
end


return M
