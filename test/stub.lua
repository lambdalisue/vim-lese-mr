-- Stands in for vim-mr in the tests, so they run without it installed.

local host = require("lese.host")

local M = {}

---Define Vim script functions named `mr#{type}#...` from `lines`.
---
---They are sourced from a file named autoload/mr/{type}.vim: Vim refuses
---(E746) to define an autoload-style function from a script whose file name
---does not match, which includes the test runner itself.
---@param type string
---@param lines string[]
function M.define(type, lines)
  local path = M.write(type, lines)
  host.cmd("source " .. host.fn.fnameescape(path))
end

---Write `lines` to {root}/autoload/mr/{type}.vim under a new directory {root}
---and return the file's path; with {root} on 'runtimepath' it is what Vim
---autoloads for `mr#{type}#...`.
---@param type string
---@param lines string[]
---@return string path
---@return string root
function M.write(type, lines)
  local root = host.fn.tempname()
  local dir = root .. "/autoload/mr"
  host.fn.mkdir(dir, "p")
  local path = dir .. "/" .. type .. ".vim"
  host.fn.writefile(lines, path)
  return path, root
end

---Remove a function `define` made, as if vim-mr were not installed.
---@param name string
function M.undefine(name)
  host.cmd("silent! delfunction " .. name)
end

return M
