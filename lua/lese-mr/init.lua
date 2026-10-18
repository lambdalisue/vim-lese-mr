-- Loading this module declares nothing; users bring the pickers in from their
-- custom.lua with define_pickers, or use the modules in pickers of their own.

local M = {}

M.source = {
  mr = require("lese-mr.source.mr"),
}

return M
