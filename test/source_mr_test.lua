local t = require("lese.testing")
local host = require("lese.host")
local mr = require("lese-mr.source.mr")
local stub = require("test.stub")

---@param type string
---@param paths string[]
local function stub_list(type, paths)
  stub.define(type, {
    "function! mr#" .. type .. "#list() abort",
    "  return " .. host.fn.string(paths),
    "endfunction",
  })
end

---@param type string
local function unstub_list(type)
  stub.undefine("mr#" .. type .. "#list")
end

t.describe("lese-mr.source.mr", function()
  t.it("emits the paths of mr#mru#list() when no type is given", function()
    stub_list("mru", { "/work/a.txt", "/work/b.txt" })
    t.eq(t.values(t.collect(mr())), { "/work/a.txt", "/work/b.txt" })
  end)

  for _, type in ipairs({ "mru", "mrw", "mrr", "mrd" }) do
    t.it("emits the paths of mr#" .. type .. "#list() for type " .. type, function()
      stub_list(type, { "/" .. type .. "/1", "/" .. type .. "/2" })
      t.eq(t.values(t.collect(mr({ type = type }))), { "/" .. type .. "/1", "/" .. type .. "/2" })
    end)
  end

  t.it("numbers the items from 1 in list order and records the path and type", function()
    stub_list("mrw", { "/work/a.txt", "/work/b.txt" })
    t.eq(t.collect(mr({ type = "mrw" })), {
      { id = 1, value = "/work/a.txt", detail = { path = "/work/a.txt", mr = { type = "mrw" } } },
      { id = 2, value = "/work/b.txt", detail = { path = "/work/b.txt", mr = { type = "mrw" } } },
    })
  end)

  t.it("keeps numbering across the chunks of a long list", function()
    local paths = {}
    for i = 1, 2500 do
      paths[i] = "/work/" .. i
    end
    stub_list("mru", paths)
    local items = t.collect(mr())
    t.eq(#items, 2500)
    t.eq(items[2500].id, 2500)
    t.eq(items[2500].value, "/work/2500")
  end)

  t.it("emits nothing for an empty list", function()
    stub_list("mrd", {})
    t.eq(t.collect(mr({ type = "mrd" })), {})
  end)

  t.it("loads vim-mr's autoload script when it is not loaded yet", function()
    unstub_list("mrd")
    local _, root = stub.write("mrd", {
      "function! mr#mrd#list() abort",
      "  return ['/autoloaded']",
      "endfunction",
    })
    host.cmd("set runtimepath+=" .. host.fn.fnameescape(root))
    local ok, items = pcall(t.collect, mr({ type = "mrd" }))
    host.cmd("set runtimepath-=" .. host.fn.fnameescape(root))
    if not ok then
      error(items, 0)
    end
    t.eq(t.values(items), { "/autoloaded" })
  end)

  t.it("says vim-mr is required when mr#{type}#list() does not exist", function()
    unstub_list("mrr")
    t.raises(function()
      t.collect(mr({ type = "mrr" }))
    end, "lese-mr: vim-mr (lambdalisue/vim-mr) is required")
  end)

  t.it("rejects a type vim-mr does not have", function()
    local opts = { type = "mrx" } ---@type any
    t.raises(function()
      mr(opts)
    end, "lese-mr: unknown type 'mrx'")
  end)

  t.it("narrows the paths in a picker", function()
    stub_list("mru", { "/work/alpha.lua", "/work/beta.lua", "/work/alphabet.txt" })
    t.snapshot(t.picker({ source = mr() }):type("alpha"):screen())
  end)
end)
