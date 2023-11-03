local M = {}

local util = require "rust-tools.util"
local function get_params()
  return {
    textDocument = vim.lsp.util.make_text_document_params(0),
    position = nil, -- get em all
  }
end

local function handler(_, result, ctx)
  if result == nil then
    return
  end
  local line = vim.fn.line('.')
  if M.options == nil then
    M.options = {}
  end
  local contents = {}
  local title = 'Codelens:'
  table.insert(contents, title)

  local index = 0
  for _, lens in pairs(result) do
    local lens_title = ''
    if lens.range.start.line == (line - 1) then
      index = index + 1
      M.options[index] = { client_id = ctx.client_id, lens = lens }
      lens_title = '[' .. index .. ']' .. ' ' .. lens.command.title
      table.insert(contents, lens_title)
    end
  end

  if #M.options == 0 then
    vim.notify('No executable codelens found at current line')
  else
    local lines = table.concat(contents, "\n")
    local config =  {
      relative = 'cursor',
      width = 30,
      height = #contents + 2,
      row = 1,
      col = 1,
      style = 'minimal',
      border = {'╭', '─', '╮', '│', '╯', '─', '╰', '│'},
    }
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(lines, "\n"))
    vim.api.nvim_open_win(bufnr, true, config)
    vim.api.nvim_set_option_value('buftype','nofile', {})
    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'q', '<cmd>q<CR>', { noremap = true, silent = true })
    vim.api.nvim_win_set_cursor(0, {2, 1})

    -- -- 定义按键映射函数
    -- local select_option = function()
    --   -- 获取当前光标所在行号
    --   local cursor_row = vim.fn.line('.')
    --
    --   -- 检查是否为有效选项行
    --   if M.options[cursor_row - 1] then
    --     -- 执行选项操作，这里只是简单地打印选项信息
    --     print('Selected option:', M.options[cursor_row - 1].lens.command.title)
    --   end
    -- end

    -- 设置按键映射，将回车键绑定到select_option函数
    -- vim.api.nvim_buf_set_keymap(bufnr, 'n', '<CR>', '<cmd>lua select_option()<CR>', { noremap = true, silent = true })

    function M.select_option()
      -- 获取当前光标所在行号
      local cursor_row = vim.fn.line('.')

      -- 检查是否为有效选项行
      if M.options[cursor_row - 1] then
        -- 执行选项操作，这里只是简单地打印选项信息
        print('Selected option:', M.options[cursor_row - 1].lens.command.title)

        -- 关闭浮动窗口
        vim.api.nvim_win_close(0, true)
      end
    end

    function M.send_enter_key()
      -- 发送回车键到当前缓冲区
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<CR>', true, false, true), 'n', true)
    end

  end

end

-- Sends the request to rust-analyzer to get cargo.tomls location and open it
function M.codelens()
  util.lsp_buf_request(0, "textDocument/codeLens", get_params(), handler)
end

return M



-- local api = vim.api
-- local lspcode = require("vim.lsp.codelens")
-- local wrap = require('lspsaga.wrap')
-- local config = require('lspsaga').config_values
-- local window = require('lspsaga.window')
-- local libs = require('lspsaga.libs')
-- local method = 'textDocument/codeLens'
-- local saga_augroup = require('lspsaga').saga_augroup
--
-- local codelens = {}
--
-- function codelens.execute_lens(lens, bufnr, client_id)
--   local client = vim.lsp.get_client_by_id(client_id)
--   local command = lens.command
--   local fn = client.commands[command.command] or vim.lsp.commands[command.command]
--   if fn then
--     fn(command, { bufnr = bufnr, client_id = client_id })
--     return
--   end
--
--   local command_provider = client.server_capabilities.executeCommandProvider
--   local commands = type(command_provider) == 'table' and command_provider.commands or {}
--   if not vim.tbl_contains(commands, command.command) then
--     vim.notify("Error", vim.log.levels.WARN)
--     return
--   end
--   client.request('workspace/executeCommand', command, function(...)
--     local result = vim.lsp.handlers['workspace/executeCommand'](...)
--     lspcode.refresh()
--     return result
--   end, bufnr)
-- end
--
-- function codelens.handler(_, result, ctx, _)
--   local line = api.nvim_win_get_cursor(0)[1]
--   local bufnr = api.nvim_get_current_buf()
--   if codelens.options == nil then
--     codelens.options = {}
--   end
--   local contents = {}
--   local title = 'Codelens:'
--   table.insert(contents, title)
--
--   local index = 0
--   for _, lens in pairs(result) do
--     local lens_title = ''
--     if lens.range.start.line == (line - 1) then
--       index = index + 1
--       codelens.options[index] = { client_id = ctx.client_id, lens = lens }
--       lens_title = '[' .. index .. ']' .. ' ' .. lens.command.title
--       table.insert(contents, lens_title)
--     end
--   end
--
--   if #codelens.options == 0 then
--     vim.notify('No executable codelens found at current line')
--   -- elseif #codelens.options == 1 then
--   --   local option = codelens.options[1]
--   --   codelens.execute_lens(option.lens, bufnr, option.client_id)
--   else
--     local truncate_line = wrap.add_truncate_line(contents)
--     table.insert(contents, 2, truncate_line)
--
--     local content_opts = {
--       contents = contents,
--       filetype = 'sagacodelens',
--       enter = true,
--       highlight = 'LspSagaCodeActionBorder'
--     }
--
--     codelens.bufnr, codelens.winid = window.create_win_with_border(content_opts)
--     api.nvim_win_set_cursor(codelens.winid, { 3, 1 })
--     api.nvim_create_autocmd('CursorMoved',{
--       group = saga_augroup,
--       buffer = codelens.bufnr,
--       callback = function()
--         codelens.set_cursor()
--       end
--     })
--     api.nvim_create_autocmd('QuitPre', {
--       buffer = codelens.bufnr,
--       callback = codelens.quit_lens_window
--     })
--
--     api.nvim_buf_add_highlight(codelens.bufnr,-1,"LspSagaCodeActionTitle",0,0,-1)
--     api.nvim_buf_add_highlight(codelens.bufnr,-1,"LspSagaCodeActionTrunCateLine",1,0,-1)
--     for i=1,#contents-2,1 do
--       api.nvim_buf_add_highlight(codelens.bufnr,-1,"LspSagaCodeActionContent",1+i,0,-1)
--     end
--     -- dsiable some move keys in codeaction
--     libs.disable_move_keys(codelens.bufnr)
--
--     codelens.apply_action_keys()
--     if config.code_action_num_shortcut then
--       local opts = {nowait = true,silent = true,noremap =true}
--       for num,_ in pairs(codelens.options) do
--         num = tostring(num)
--         local rhs = string.format("<cmd>lua require('lspsaga.codelens').do_code_lens('%s')<CR>", num)
--         api.nvim_buf_set_keymap(codelens.bufnr,'n',num,rhs,opts)
--       end
--     end
--   end
-- end
--
-- function codelens.set_cursor ()
--   local col = 1
--   local current_line = api.nvim_win_get_cursor(codelens.winid)[1]
--
--   if current_line == 1 then
--     api.nvim_win_set_cursor(codelens.winid,{3,col})
--   elseif current_line == 2 then
--     api.nvim_win_set_cursor(codelens.winid,{2+#codelens.options,col})
--   elseif current_line == #codelens.options + 3 then
--     api.nvim_win_set_cursor(codelens.winid,{3,col})
--   end
-- end
--
-- function codelens.quit_lens_window()
--   if codelens.bufnr == 0 and codelens.winid == 0 then
--     return
--   end
--   window.nvim_close_valid_window(codelens.winid)
--   codelens.winid = 0
--   codelens.bufnr = 0
--   codelens.options = {} -- TODO maybe also do this other place
-- end
--
-- local apply_keys = libs.apply_keys("codelens")
--
-- function codelens.apply_action_keys()
--   local lens = {
--     ['quit_lens_window'] = config.code_action_keys.quit,
--     ['do_code_lens'] = config.code_action_keys.exec,
--   }
--   for func, keys in pairs(lens) do
--     apply_keys(func, keys)
--   end
-- end
--
-- function codelens.do_code_lens(num)
--   local number = num and tonumber(num) or tonumber(vim.fn.expand("<cword>"))
--   local lens = codelens.options[number].lens
--   local client_id = codelens.options[number].client_id
--   codelens.execute_lens(lens, 0, client_id)
--   codelens.quit_lens_window()
-- end
--
-- function codelens.run()
--   local bufnr = api.nvim_get_current_buf()
--   local params = {
--     textDocument = vim.lsp.util.make_text_document_params()
--   }
--   vim.lsp.buf_request(bufnr, method, params, codelens.handler)
-- end
--
-- return codelens

