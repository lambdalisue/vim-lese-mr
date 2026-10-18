# vim-lese-mr

An extension for [lese](https://github.com/lambdalisue/vim-lese), the Lua
fuzzy finder for Vim and Neovim, that lists the files, repositories and
directories [vim-mr](https://github.com/lambdalisue/vim-mr) records (MRU, MRW,
MRR, MRD) in lese pickers.

## How it is built

- **Test first.** Red → green → refactor. Write the failing test before the
  code that makes it pass.
- **Each layer holds one thing.** Put a fact in the one layer that owns it,
  and nowhere else.

  | Layer | Holds |
  | --- | --- |
  | `README.md` | what the extension does and the `custom.lua` line that enables it |
  | `doc/lese-mr.txt` | the user manual: the modules, their options and the pickers |
  | Tests | the details that pin the behaviour down: rules, boundaries, tables |
  | Code | how it is done |
  | Commits | why a change was made |
  | Comments | why it is not done another way |

- **Dependencies are current.** Before adding or bumping one, look up its
  latest release in the registry. Do not copy a version from memory or from
  another repository.

## Rules of an extension

lese runs the same Lua on Neovim and on Vim (+lua). You cannot open the
picker's UI, so you prove the extension works with tests and `lese-run`, on
both editors. The module format is specified in vim-lese's
`docs/spec/modules.md`; the types are in `lua/lese/types.lua` (both under
`.deps/vim-lese/` after `just deps`).

- Lua lives under `lua/lese-mr/`; never add files under `lua/lese/`,
  which is lese's own namespace.
- Write only the Lua 5.1 subset: no `goto`, `//`, bitwise operators, `utf8`,
  or `table.unpack` (use `require("lese.core.compat").unpack`). `stylua.toml`
  and selene make `just ci` fail on them.
- Reach the editor only through `ctx.host` (`ctx.host.fn.getcwd()`,
  `ctx.host.cmd(...)`); tests use `require("lese.host")`. Never touch
  `vim.api`, `vim.cmd`, `vim.fn`, `vim.uv`, `vim.loop`, `vim.command` or
  `vim.list`: they differ between Neovim and Vim, and selene rejects them.
- Define every module with `require("lese.define")` (`define.source`,
  `define.matcher`, …) and give it a `name` like
  `"lese-mr.source.mr"`. It checks the contract at run time.
- Hand items over with `ctx:emit()`; every item has `id` (unique within the
  source), `value` (a string) and `detail` (a table). Annotate the `detail`
  with a LuaCATS class.
- Call `ctx:checkpoint()` in every loop over many items. Run commands with
  `ctx:spawn(cmd, { on_stdout = function(line) ... end })`, never with
  `system()`.
- Modules that take options are functions returning the module; users always
  call them, options or not.
- The extension adds no picker by itself and has no `plugin/` directory.
  `require("lese-mr").define_pickers(x)` declares its recommended pickers
  for users to call from their `custom.lua`.
- Check for what you need from lese by feature (`pcall(require, ...)`, a
  field's presence), never by version.
- Reach vim-mr only through its autoload functions (`mr#{type}#list()`,
  `mr#{type}#delete(path)`) called with `ctx.host.fn`. Tests do not install
  vim-mr: they define those functions themselves with
  `require("lese.host").fn.execute(...)`, and `test/fixture/vim-mr` stands in
  for it in `just run`.

## Steps

1. Write the test first, in `test/<module>_test.lua`:

   ```lua
   local t = require("lese.testing")
   local host = require("lese.host")
   local mr = require("lese-mr.source.mr")

   t.describe("lese-mr.source.mr", function()
     t.it("emits the paths mr#mru#list() returns", function()
       host.fn.execute({
         "function! mr#mru#list() abort",
         "  return ['/a', '/b']",
         "endfunction",
       })
       t.eq(t.values(t.collect(mr())), { "/a", "/b" })
     end)

     t.it("renders the picker as expected", function()
       t.snapshot(t.picker({ source = mr() }):type("b"):screen())
     end)
   end)
   ```

   `t.collect`, `t.curate`, `t.match`, `t.sort`, `t.render`, `t.preview`,
   `t.invoke` and `t.refine` run one module. `t.picker(params)` drives a
   whole picker: `:type(text)`, `:press("<C-n>")`, `:screen()`, `:items()`,
   `:preview()`, `:invoke(name)`. `t.snapshot(text)` compares with a file
   under `test/__snapshots__/`.
2. Run it and see it fail: `just test` (or `just test <filter>`,
   `just test-on nvim`).
3. Implement until `just test` passes on every host.
4. Declare the picker in `define_pickers` and try it without the UI.
   `test/custom.lua` is the `custom.lua` `lese-run` loads:

   ```sh
   just run mrw --rtp test/fixture/vim-mr --query "lic"      # both editors, diffed
   just run mru --rtp test/fixture/vim-mr --preview 1 --json
   ```

   `--rtp test/fixture/vim-mr` puts a stand-in vim-mr with fixed lists on
   'runtimepath'; pass `--rtp` to a real vim-mr checkout to see the history
   of this machine instead.

   Read the output: the first line is the picker, the query and the count of
   items shown over collected; `>` marks the cursor row, `*` a selected row,
   and brackets show what matched. `just run` fails when Neovim and Vim print
   different results. `.deps/vim-lese/bin/lese-run --help` lists every option.
5. Update snapshots only when the change is intended: `just snapshot`, then
   read the diff.

## Done means

- `just ci` is green: format, selene with lese's standard,
  lua-language-server with no warning, the tests on Neovim, Vim with PUC Lua
  and Vim with LuaJIT, and the mrw picker printing the same on both editors.
- `just run <picker>` prints the same result on both editors for every
  picker `define_pickers` declares.
- `README.md` shows the `custom.lua` line that brings the pickers in.

## When something fails

Errors name the module, the item and the field, for example
`lese: source 'lese-mr.source.mr' emitted item #3: field 'value' must be
a string, got nil`. Fix exactly what it names. A warning that a module "ran
… ms without ctx:checkpoint()" means a loop needs a checkpoint.

## Quality gate

Run `just ci` before reporting a change as done. CI runs the same recipe.

Run `just deps` once first: it clones lese into `.deps/vim-lese`. To build
against a lese checkout of your own instead, set `LESE_PATH` to it; every
recipe then uses that checkout and `just deps` does nothing.

## Layout

| Path | What lives there |
| --- | --- |
| `lua/lese-mr/` | `init.lua` with `define_pickers`, and the modules (`source/`, `matcher/`, …) |
| `test/` | `run.lua`, `*_test.lua`, `custom.lua` for `lese-run`, `__snapshots__/` |
| `test/fixture/vim-mr/` | a stand-in vim-mr with fixed lists, for `just run` |
| `doc/` | the Vim help file |
| `.deps/` | the lese checkout `just deps` clones; not tracked |

## Language

- README, docs and commit messages: English
- Code comments, log and error messages: English

## Commits

Scoped Commits:

```
<scope>: <description>

<why this change is needed>
```

- The scope names where the change is, from the table below. Several scopes
  are joined with `, `; a change across the whole tree uses `treewide`.
- The description starts in lower case, has no trailing period, and stays
  within 72 characters.
- The body explains why. The code shows how; the tests show what.
- A release commit is `release: vX.Y.Z`.
- A breaking change says so in the body and carries a `BREAKING CHANGE:`
  trailer.

| Scope | Covers |
| --- | --- |
| `lua` | `lua/lese-mr/` |
| `test` | `test/` |
| `doc` | `doc/` |
| `docs` | `README.md` |
| `ci` | `.github/` |
| `nix` | `flake.nix`, `flake.lock` |
| `deps` | dependency updates |

Add a row when a new area appears.
