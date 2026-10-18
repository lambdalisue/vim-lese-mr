local t = require("lese.testing")
local host = require("lese.host")
local custom = require("lese.custom")
local builtin = require("lese.builtin")
local stub = require("test.stub")

local sep = host.fn.has("win32") == 1 and "\\" or "/"

---@param opts? lese-mr.PickersOptions
local function define_pickers(opts)
  custom.load_function(function(x)
    require("lese-mr").define_pickers(x, opts)
  end)
end

---@param name string
---@return lese.PickerDefinition
local function picker(name)
  return assert(custom.get(name), "no picker " .. name)
end

---@param name string
---@return string[]
local function action_names(name)
  local names = {}
  for action in pairs(picker(name).actions) do
    names[#names + 1] = action
  end
  table.sort(names)
  return names
end

---Drive the picker `name` of the loaded custom as lese-run does.
---@param name string
---@return lese.Driver
local function drive(name)
  local definition = picker(name)
  local built = definition.build({})
  return t.picker({
    name = definition.name,
    source = built.source,
    matchers = built.matchers,
    sorters = definition.sorters,
    renderers = definition.renderers,
    previewers = definition.previewers,
    actions = definition.actions,
    default_action = definition.default_action,
  })
end

---@param type string
---@param paths string[]
local function stub_list(type, paths)
  stub.define(type, {
    "function! mr#" .. type .. "#list() abort",
    "  return " .. host.fn.string(paths),
    "endfunction",
  })
end

local PATH_ACTIONS = {
  "cd",
  "echo",
  "lcd",
  "mr-delete",
  "open",
  "open:drop",
  "open:split",
  "open:tabedit",
  "open:vsplit",
  "quickfix",
  "quickfix:copen",
  "systemopen",
  "tcd",
  "yank",
}

local DIRECTORY_ACTIONS = {
  "cd",
  "cd-and-open",
  "echo",
  "lcd",
  "mr-delete",
  "open",
  "open:drop",
  "open:split",
  "open:tabedit",
  "open:vsplit",
  "quickfix",
  "quickfix:copen",
  "systemopen",
  "tcd",
  "yank",
}

t.describe("lese-mr.define_pickers", function()
  t.it("declares the mru, mrw, mrr and mrd pickers", function()
    define_pickers()
    t.eq(custom.names(), { "mru", "mrw", "mrr", "mrd" })
  end)

  t.it("lists the matching vim-mr list in each picker", function()
    for _, type in ipairs({ "mru", "mrw", "mrr", "mrd" }) do
      stub_list(type, { host.fn.getcwd() .. sep .. type })
    end
    define_pickers()
    for _, type in ipairs({ "mru", "mrr", "mrd" }) do
      local items = t.collect(picker(type).build({}).source)
      t.eq(items[1].detail.mr.type, type)
    end
    t.eq(t.values(t.collect(picker("mrw").build({}).source)), { "mrw" })
  end)

  t.it("opens files from mru and mrw by default, with the file previewer", function()
    define_pickers()
    for _, name in ipairs({ "mru", "mrw" }) do
      t.eq(picker(name).default_action, "open")
      t.eq(action_names(name), PATH_ACTIONS)
      t.eq(picker(name).previewers[1].name, "builtin.previewer.file")
      t.eq(#picker(name).sorters, 3)
    end
  end)

  t.it(
    "changes into a directory and opens it from mrr and mrd by default, without a preview",
    function()
      define_pickers()
      for _, name in ipairs({ "mrr", "mrd" }) do
        t.eq(picker(name).default_action, "cd-and-open")
        t.eq(action_names(name), DIRECTORY_ACTIONS)
        t.eq(picker(name).previewers, {})
        t.eq(picker(name).sorters, {})
        local coordinator = assert(picker(name).coordinator, "no coordinator")
        t.eq(coordinator.layout({ width = 80, height = 24 }).preview, nil)
      end
    end
  )

  t.it("keeps only the files under the current directory in mrw, relative to it", function()
    local cwd = host.fn.getcwd()
    stub_list("mrw", {
      cwd .. sep .. "lua" .. sep .. "a.lua",
      sep == "/" and "/elsewhere/b.lua" or "Z:\\elsewhere\\b.lua",
      cwd .. sep .. "c.lua",
    })
    define_pickers()
    local items = t.collect(picker("mrw").build({}).source)
    t.eq(t.values(items), { "lua" .. sep .. "a.lua", "c.lua" })
    t.eq(items[1].detail.path, cwd .. sep .. "lua" .. sep .. "a.lua")
  end)

  t.it("merges the actions given in opts over the defaults", function()
    local noop = builtin.action.noop()
    define_pickers({ actions = { noop = noop, open = noop } })
    for _, name in ipairs({ "mru", "mrw", "mrr", "mrd" }) do
      t.eq(picker(name).actions.noop, noop)
      t.eq(picker(name).actions.open, noop)
      t.ok(picker(name).actions["mr-delete"])
    end
  end)

  t.it("renames pickers and leaves out those named false", function()
    define_pickers({ names = { mru = "recent", mrd = false } })
    t.eq(custom.names(), { "recent", "mrw", "mrr" })
  end)

  t.it("narrows the files of mrw in a picker", function()
    local cwd = host.fn.getcwd()
    stub_list("mrw", { cwd .. sep .. "init.lua", cwd .. sep .. "README.md" })
    define_pickers()
    t.snapshot(drive("mrw"):type("init"):screen())
  end)
end)
