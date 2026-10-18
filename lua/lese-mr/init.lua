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

---@class lese-mr.PickersOptions
---@field actions? table<string, lese.Action> -- merged into every picker's actions, over the defaults
---@field names? table<string, string|false>  -- rename a picker (`mru = "recent"`) or leave it out (`mrd = false`)

---@param ... table<string, lese.Action>
---@return table<string, lese.Action>
local function merge(...)
  local out = {}
  for i = 1, select("#", ...) do
    for name, action in pairs((select(i, ...))) do
      out[name] = action
    end
  end
  return out
end

---Declare the pickers this extension recommends:
---
---  - `mru`: most recently used files
---  - `mrw`: most recently written files under the current directory
---  - `mrr`: most recently used repositories
---  - `mrd`: most recently used directories
---
---Call it from custom.lua: `require("lese-mr").define_pickers(x)`.
---@param x lese.Entrypoint
---@param opts? lese-mr.PickersOptions
function M.define_pickers(x, opts)
  opts = opts or {}
  local names = opts.names or {}
  local builtin = require("lese.builtin")
  local std = require("lese.std")
  local mr = M.source.mr

  local function define(name, source, params)
    local renamed = names[name]
    if renamed == false then
      return
    end
    x.define_picker_from_source(renamed or name, source, params)
  end

  local function actions(extra)
    return merge(
      builtin.action.default_open_actions,
      builtin.action.default_systemopen_actions,
      builtin.action.default_cd_actions,
      builtin.action.default_quickfix_actions,
      builtin.action.default_echo_actions,
      builtin.action.default_yank_actions,
      M.action.default_mr_delete_actions,
      extra,
      opts.actions or {}
    )
  end

  local function renderers()
    return {
      std.compose_renderers(builtin.renderer.smart_path(), builtin.renderer.nerdfont()),
      builtin.renderer.nerdfont(),
      builtin.renderer.noop(),
    }
  end

  local function file_params()
    return {
      matchers = { builtin.matcher.fzf() },
      sorters = {
        builtin.sorter.noop(),
        builtin.sorter.lexical(),
        builtin.sorter.lexical({ reverse = true }),
      },
      renderers = renderers(),
      previewers = { builtin.previewer.file() },
      actions = actions({}),
      default_action = "open",
    }
  end

  -- A repository or directory has nothing for the file previewer to show, so
  -- these pickers give the list the whole width.
  local function directory_params()
    return {
      matchers = { builtin.matcher.fzf() },
      renderers = renderers(),
      actions = actions({
        ["cd-and-open"] = std.compose_actions(builtin.action.cd(), builtin.action.open()),
      }),
      default_action = "cd-and-open",
      coordinator = builtin.coordinator.modern({ hide_preview = true }),
    }
  end

  define("mru", mr({ type = "mru" }), file_params())
  define(
    "mrw",
    std.refine_source(mr({ type = "mrw" }), builtin.refiner.cwd(), builtin.refiner.relative_path()),
    file_params()
  )
  define("mrr", mr({ type = "mrr" }), directory_params())
  define("mrd", mr({ type = "mrd" }), directory_params())
end

return M
