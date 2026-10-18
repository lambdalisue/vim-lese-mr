local define = require("lese.define")

---Which vim-mr list: most recently used files, written files, repositories
---or directories.
---@alias lese-mr.Type "mru"|"mrw"|"mrr"|"mrd"

---The detail of an item lese-mr.source.mr emits.
---@class lese-mr.source.MrDetail
---@field path string            -- the path as vim-mr recorded it
---@field mr { type: lese-mr.Type } -- the list the path came from

---Options of lese-mr.source.mr.
---@class lese-mr.source.MrOptions
---@field type? lese-mr.Type -- the list to read, default "mru"

local TYPES = { mru = true, mrw = true, mrr = true, mrd = true }

local CHUNK_SIZE = 1000

---@param host lese.Host
---@param type lese-mr.Type
---@return string[]
local function list(host, type)
  local name = "mr#" .. type .. "#list"
  -- Load the autoload script by hand rather than calling the function and
  -- catching E117: Vim records a caught error all the same, which makes
  -- `vim -es` exit non-zero and may still show the message.
  if host.fn.exists("*" .. name) == 0 then
    host.cmd("runtime autoload/mr/" .. type .. ".vim")
    if host.fn.exists("*" .. name) == 0 then
      error("lese-mr: vim-mr (lambdalisue/vim-mr) is required", 0)
    end
  end
  return host.call(name)
end

---Emits the paths vim-mr lists for `type` (mr#{type}#list()), in that order.
---@param opts? lese-mr.source.MrOptions
---@return lese.Source
return function(opts)
  local type = (opts or {}).type or "mru"
  if not TYPES[type] then
    error(string.format("lese-mr: unknown type '%s'; use mru, mrw, mrr or mrd", type), 2)
  end

  return define.source({
    name = "lese-mr.source.mr",
    collect = function(ctx)
      local paths = list(ctx.host, type)
      local items = {}
      for i, path in ipairs(paths) do
        items[#items + 1] = { id = i, value = path, detail = { path = path, mr = { type = type } } }
        if #items == CHUNK_SIZE then
          ctx:emit(items)
          ctx:checkpoint()
          items = {}
        end
      end
      ctx:emit(items)
    end,
  })
end
