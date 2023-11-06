local util = require "rust-tools.util"

local M = {}

local latest_buf_id = nil

local function get_command(args)
  local ret = " "

  local dir = args.workspaceRoot

  ret = string.format("cd '%s' && cargo ", dir)

  for _, value in ipairs(args.cargoArgs) do
    ret = ret .. value .. " "
  end

  for _, value in ipairs(args.cargoExtraArgs) do
    ret = ret .. value .. " "
  end

  if not vim.tbl_isempty(args.executableArgs) then
    ret = ret .. "-- "
    for _, value in ipairs(args.executableArgs) do
      ret = ret .. value .. " "
    end
  end
  return ret
end

function M.run_command(args)
  -- check if a buffer with the latest id is already open, if it is then
  -- delete it and continue
  util.delete_buf(latest_buf_id)

  -- create the new buffer
  latest_buf_id = vim.api.nvim_create_buf(false, true)

  -- split the window to create a new buffer and set it to our window
  util.split(latest_buf_id)

  util.resize "-5"

  local command = get_command(args)

  -- run the command
  vim.fn.termopen(command)

  -- when the buffer is closed, set the latest buf id to nil else there are
  -- some edge cases with the id being sit but a buffer not being open
  local function onDetach(_, _)
    latest_buf_id = nil
  end
  vim.api.nvim_buf_attach(latest_buf_id, false, { on_detach = onDetach })
end

return M
