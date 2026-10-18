local t = require("lese.testing")
local host = require("lese.host")
local mr_delete = require("lese-mr.action.mr_delete")
local stub = require("test.stub")

---Make every mr#{type}#delete() record its call in g:lese_mr_deleted.
local function stub_delete()
  host.cmd("let g:lese_mr_deleted = []")
  for _, type in ipairs({ "mru", "mrw", "mrr", "mrd" }) do
    stub.define(type, {
      "function! mr#" .. type .. "#delete(filename) abort",
      "  call add(g:lese_mr_deleted, ['" .. type .. "', a:filename])",
      "endfunction",
    })
  end
end

---@param type string
---@param path string
---@return lese.Item
local function item(type, path)
  return { id = path, value = path, detail = { path = path, mr = { type = type } } }
end

t.describe("lese-mr.action.mr_delete", function()
  t.it("deletes the item under the cursor from its list", function()
    stub_delete()
    t.invoke(mr_delete(), { item = item("mrw", "/work/a.txt") })
    t.eq(host.eval("g:lese_mr_deleted"), { { "mrw", "/work/a.txt" } })
  end)

  t.it("deletes every selected item from its own list instead of the cursor item", function()
    stub_delete()
    t.invoke(mr_delete(), {
      item = item("mru", "/work/cursor.txt"),
      selected_items = { item("mru", "/work/a.txt"), item("mrd", "/work") },
    })
    t.eq(host.eval("g:lese_mr_deleted"), { { "mru", "/work/a.txt" }, { "mrd", "/work" } })
  end)

  t.it("skips items that did not come from vim-mr", function()
    stub_delete()
    t.invoke(mr_delete(), {
      selected_items = { t.item("/elsewhere"), item("mrr", "/repo") },
    })
    t.eq(host.eval("g:lese_mr_deleted"), { { "mrr", "/repo" } })
  end)

  t.it("does nothing without an item", function()
    stub_delete()
    t.invoke(mr_delete(), {})
    t.eq(host.eval("g:lese_mr_deleted"), {})
  end)

  t.it("closes the picker afterwards", function()
    stub_delete()
    t.eq(t.invoke(mr_delete(), { item = item("mru", "/work/a.txt") }), nil)
  end)
end)
