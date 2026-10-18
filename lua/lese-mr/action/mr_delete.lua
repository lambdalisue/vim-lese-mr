local define = require("lese.define")

---Deletes each chosen item (the selected items, or the item under the cursor)
---from the vim-mr list it came from, with mr#{type}#delete(detail.path).
---Items without `detail.mr` did not come from lese-mr.source.mr and are skipped.
---@return lese.Action
return function()
  return define.action({
    name = "lese-mr.action.mr_delete",
    invoke = function(ctx, params)
      for _, item in ipairs(params.selected_items or { params.item }) do
        ctx:checkpoint()
        local detail = item.detail ---@type lese-mr.source.MrDetail
        if detail.mr then
          ctx.host.call("mr#" .. detail.mr.type .. "#delete", detail.path)
        end
      end
    end,
  })
end
