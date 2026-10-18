local t = require("lese.testing")

t.describe("lese-mr", function()
  t.it("exposes the source as source.mr", function()
    t.eq(require("lese-mr").source.mr, require("lese-mr.source.mr"))
  end)

  t.it("exposes the action as action.mr_delete", function()
    t.eq(require("lese-mr").action.mr_delete, require("lese-mr.action.mr_delete"))
  end)

  t.it("offers mr-delete as the default action set", function()
    local actions = require("lese-mr").action.default_mr_delete_actions
    local names = {}
    for name, action in pairs(actions) do
      names[#names + 1] = name .. "=" .. action.name
    end
    t.eq(names, { "mr-delete=lese-mr.action.mr_delete" })
  end)
end)
