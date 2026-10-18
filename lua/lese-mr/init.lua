-- Loading this module declares nothing; users bring the pickers in from their
-- custom.lua with define_pickers, or use the modules in pickers of their own.

local M = {}

M.source = {
  mr = require("lese-mr.source.mr"),
}

M.action = {
  mr_delete = require("lese-mr.action.mr_delete"),
}

---`mr-delete`, to merge into a picker's actions.
M.action.default_mr_delete_actions = {
  ["mr-delete"] = M.action.mr_delete(),
}

return M
