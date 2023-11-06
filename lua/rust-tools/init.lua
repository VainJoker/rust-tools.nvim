local open_cargo_toml = require "rust-tools.open_cargo_toml"
local runnables       = require "rust-tools.runnables"
local expand_macro    = require "rust-tools.expand_macro"
local external_docs   = require "rust-tools.external_docs"
local hover_action    = require "rust-tools.hover_action"
local codelens        = require "rust-tools.codelens"
local rr              = require "rust-tools.rr"
local M = {}

function M.setup(opts)
  opts = opts or {}
  vim.lsp.commands["rust-analyzer.runSingle"] = function(command)
    rr.run_command(command.arguments[1].args)
  end
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

end


return M

