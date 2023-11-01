-- local rt = require("rust-tools")

local M = {}

local util = require "rust-tools.util"
local executors = require "rust-tools.executors"
-- local function get_params()
--   return vim.lsp.util.make_position_params()
-- end

local latest_buf_id = nil

local function get_params()
  return vim.lsp.util.make_position_params()
end

-- parse the lines from result to get a list of the desirable output
-- Example:
-- // Recursive expansion of the eprintln macro
-- // ============================================

-- {
--   $crate::io::_eprint(std::fmt::Arguments::new_v1(&[], &[std::fmt::ArgumentV1::new(&(err),std::fmt::Display::fmt),]));
-- }
local function parse_lines(t)
  local ret = {}

  local name = t.name
  local text = "// Recursive expansion of the " .. name .. " macro"
  table.insert(ret, "// " .. string.rep("=", string.len(text) - 3))
  table.insert(ret, text)
  table.insert(ret, "// " .. string.rep("=", string.len(text) - 3))
  table.insert(ret, "")

  local expansion = t.expansion
  for string in string.gmatch(expansion, "([^\n]+)") do
    table.insert(ret, string)
  end

  return ret
end

local function handler(_, result)
  if result == nil then
    vim.api.nvim_out_write("No macro under cursor!\n")
    return
  end

  executors.ui(parse_lines(result),"nofile","rust")
end

-- Sends the request to rust-analyzer to get cargo.tomls location and open it
function M.expand_macro()
  util.lsp_buf_request(0, "rust-analyzer/expandMacro", get_params(), handler)
end

return M
