-- The custom.lua `just run` hands to lese-run: the pickers users get from
-- define_pickers, so lese-run tries exactly those.
---@param x lese.Entrypoint
return function(x)
  require("lese-mr").define_pickers(x)
end
