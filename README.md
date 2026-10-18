# vim-lese-mr

An extension for [lese](https://github.com/lambdalisue/vim-lese), the Lua
fuzzy finder for Vim and Neovim, that brings the lists
[vim-mr](https://github.com/lambdalisue/vim-mr) records into lese pickers:

| Picker | Lists | Default action |
| --- | --- | --- |
| `mru` | most recently used files | open the file |
| `mrw` | most recently written files under the current directory | open the file |
| `mrr` | most recently used repositories | `cd` into it and open it |
| `mrd` | most recently used directories | `cd` into it and open it |

Every picker also has `mr-delete`, which removes the chosen entries from the
list they came from. It is the successor of fall-extra's `mr` source and
`mr-delete` action.

## Install

Install three plugins with any plugin manager:

- [vim-mr](https://github.com/lambdalisue/vim-mr), which records the lists
- [vim-lese](https://github.com/lambdalisue/vim-lese)
- this plugin, `lambdalisue/vim-lese-mr`

For example, with [vim-plug](https://github.com/junegunn/vim-plug):

```vim
Plug 'lambdalisue/vim-mr'
Plug 'lambdalisue/vim-lese'
Plug 'lambdalisue/vim-lese-mr'
```

## Usage

This plugin adds nothing on load. Bring its pickers in from your
`custom.lua` (`:LeseCustom` opens it):

```lua
return function(x)
  -- ... your own pickers ...
  require("lese-mr").define_pickers(x)
end
```

Then `:Lese mru`, `:Lese mrw`, `:Lese mrr` and `:Lese mrd` open the pickers.

`define_pickers` takes options to merge more actions into every picker, and
to rename pickers or leave them out:

```lua
local builtin = require("lese.builtin")
require("lese-mr").define_pickers(x, {
  actions = { ["quickfix:qfreplace"] = builtin.action.quickfix({ after = "Qfreplace" }) },
  names = { mru = "recent", mrd = false }, -- :Lese recent; no mrd picker
})
```

### Building your own pickers

To declare the pickers yourself, use the modules instead of
`define_pickers`:

```lua
local builtin = require("lese.builtin")
local mr = require("lese-mr")

return function(x)
  local actions = { ["mr-delete"] = mr.action.mr_delete() }
  for name, action in pairs(builtin.action.default_open_actions) do
    actions[name] = action
  end
  x.define_picker_from_source("mru", mr.source.mr({ type = "mru" }), {
    matchers = { builtin.matcher.fzf() },
    previewers = { builtin.previewer.file() },
    actions = actions,
    default_action = "open",
  })
end
```

`:help lese-mr` describes every module and option.

## Development

Enter the development shell with `nix develop` (or copy `.envrc.sample` to
`.envrc` and `direnv allow`), then:

```sh
just deps   # clone lese into .deps/vim-lese (once; again to update it)
just ci     # everything CI runs: format check, lint, tests on every host,
            # and the mrw picker on Neovim and Vim
```

To develop against a lese checkout of your own, set `LESE_PATH` to it; every
recipe then uses that checkout and `just deps` does nothing:

```sh
LESE_PATH=~/src/vim-lese just ci
```

Other recipes:

```sh
just fmt                    # format every source
just test [filter]          # the tests on every host, or those matching filter
just test-on nvim           # the tests on one host: nvim, vim or vim-luajit
just snapshot               # write the snapshots anew; read the diff after
just run mru --rtp test/fixture/vim-mr   # a picker, on both editors, diffed
```

`test/fixture/vim-mr` is a stand-in for vim-mr with fixed lists; pass
`--rtp` to a vim-mr checkout instead to see this machine's history.
[AGENTS.md](AGENTS.md) is the guide for changing the code.

## License

MIT. See [LICENSE](LICENSE).
