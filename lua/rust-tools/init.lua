local open_cargo_toml = require "rust-tools.open_cargo_toml"
local runnables       = require "rust-tools.runnables"
local expand_macro    = require "rust-tools.expand_macro"
local external_docs   = require "rust-tools.external_docs"
local hover_action    = require "rust-tools.hover_action"
local codelens        = require "rust-tools.codelens"
local M = {}

-- 创建浮动窗口
local function create_float_window(content)
  -- 设置浮动窗口布局和大小
  local width = 30
  local height = #content + 2
  local row = (vim.o.lines - height) / 2
  local col = (vim.o.columns - width) / 2

  -- 创建新的浮动窗口
  local win_id = vim.api.nvim_open_win(0, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = {'╭', '─', '╮', '│', '╯', '─', '╰', '│'},
  })

  -- 在浮动窗口中显示内容
  vim.api.nvim_buf_set_option(0, 'modifiable', true)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, content)
  vim.api.nvim_buf_set_option(0, 'modifiable', false)

  return win_id
end

-- 获取用户输入选项
local function get_user_input()
  vim.cmd('startinsert')
  local input = vim.fn.input('')
  vim.cmd('stopinsert')
  return input
end

-- 主要逻辑
local function main()
  local content = { "Codelens:", "[1] ▶︎ Run Test", "[2] Debug" }
  local win_id = create_float_window(content)

  while true do
    local option = tonumber(get_user_input())
    if option == 1 then
      -- 执行 Run Test 的操作
      print("Running test...")
      break
    elseif option == 2 then
      -- 执行 Debug 的操作
      print("Debugging...")
      break
    end
  end

  -- 关闭浮动窗口
  vim.api.nvim_win_close(win_id, true)
end



function M.setup(opts)
  opts = opts or {}

   vim.keymap.set("n", "<Leader>ic", function()
     open_cargo_toml.open_cargo_toml()
   end)
   vim.keymap.set("n", "<Leader>ir", function()
     runnables.runnables()
   end)
   vim.keymap.set("n", "<Leader>iu", function()
     expand_macro.expand_macro()
   end)
   vim.keymap.set("n", "<Leader>it", function()
     external_docs.open_external_docs()
   end)
   vim.keymap.set("n", "<Leader>ia", function()
     hover_action.hover_action()
   end)
   vim.keymap.set("n", "<Leader>il", function()
     codelens.codelens()
   end)
   vim.keymap.set("n", "<Leader>im", function()
     main()
   end)


end


return M

