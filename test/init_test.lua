local t = require("lese.testing")

t.describe("lese-mr", function()
  t.it("exposes the source as source.mr", function()
    t.eq(require("lese-mr").source.mr, require("lese-mr.source.mr"))
  end)
end)
