local util = require "rust-tools.util"
local executors= require "rust-tools.executors"
local M = {}

local function get_params()
  return {
    textDocument = vim.lsp.util.make_text_document_params(0),
    position = nil, -- get em all
  }
end

local function get_options(result)
  local option_strings = {}

  for _, runnable in ipairs(result) do
    local str = runnable.label
    table.insert(option_strings, str)
  end

  return option_strings
end

function M.run_command(args)
  if args == nil then
    return
  end

  local ret = {}
  local cwd = args.workspaceRoot
  local command = "cargo"

  ret = vim.list_extend({}, args.cargoArgs or {})
  ret = vim.list_extend(ret, args.cargoExtraArgs or {})
  table.insert(ret, "--")
  ret = vim.list_extend(ret, args.executableArgs or {})

  local cmd = executors.chain_commands({
    executors.make_command_from_args("cd", { cwd }),
    executors.make_command_from_args(command, ret),
  })

  local output = executors.run_command(cmd)

  executors.ui(output,"rt","bash")
end

local function handler(_, result)
  if result == nil then
    return
  end

  local options = get_options(result)

   vim.ui.select(options, { prompt = "Runnables", kind = "rust-tools/runnables" }, function(_, choice)
     if not choice or choice < 1 or choice > #result then
       return
     end
      M.run_command(result[choice].args)
   end)
end

function M.runnables()
  util.lsp_buf_request(0, "experimental/runnables", get_params(), handler)
end

return M
