# Run `nix develop` (or use direnv) first so every tool is on PATH, then
# `just deps` once to fetch lese.

set shell := ["bash", "-euo", "pipefail", "-c"]
set positional-arguments

# The lese checkout to build and test against: LESE_PATH when it is set (a
# clone of vim-lese you are changing alongside), else the one `just deps`
# clones.
lese := env("LESE_PATH", ".deps/vim-lese")

# The hosts `just test` runs on, in order. CI on Windows narrows it to `nvim`.
hosts := env("HOSTS", "nvim vim vim-luajit")

# List the recipes.
default:
    @just --list

# Clone lese into .deps/vim-lese, or update the clone; nothing when LESE_PATH is set.
deps:
    if [ -n "${LESE_PATH:-}" ]; then \
      echo "deps: using lese at $LESE_PATH"; \
    elif [ -d .deps/vim-lese/.git ]; then \
      git -C .deps/vim-lese pull --ff-only; \
    else \
      git clone --depth 1 https://github.com/lambdalisue/vim-lese .deps/vim-lese; \
    fi

# Format every source.
fmt:
    stylua .
    nixfmt flake.nix

# Check formatting without changing files.
fmt-check:
    stylua --check .

# Lint with lese's selene standard, and type-check the LuaCATS annotations.
lint:
    cp -- {{quote(lese)}}/selene/lese.yml lese.yml
    selene .
    # .luarc.json finds lese in .deps/vim-lese; point a copy at LESE_PATH instead.
    if [ -n "${LESE_PATH:-}" ]; then \
      mkdir -p .deps; \
      LIB="$(CDPATH= cd -- "$LESE_PATH" && pwd)/lua" perl -MJSON::PP -0777 -ne '$c = JSON::PP->new->canonical->pretty; $j = $c->decode($_); $j->{"workspace.library"} = [ map { $_ eq ".deps/vim-lese/lua" ? $ENV{LIB} : $_ } @{ $j->{"workspace.library"} } ]; print $c->encode($j)' .luarc.json > .deps/luarc.json; \
      config=.deps/luarc.json; \
    else \
      config=.luarc.json; \
    fi; \
    lua-language-server --check . --checklevel=Warning --configpath "$PWD/$config"

# Run the tests on every host, or only those whose name contains FILTER.
test filter="":
    for host in {{hosts}}; do just test-on "$host" "$1"; done

# Run the tests on one host: nvim, vim or vim-luajit.
test-on host filter="":
    LESE_TEST_ROOT={{quote(lese)}} TEST_FILTER="$2" {{ if host == "nvim" { "nvim --headless --clean" } else { host + " -Nu NONE -i NONE -es" } }} --cmd 'let &rtp = escape($LESE_TEST_ROOT, ",") . ",.," . &rtp' -c 'luafile test/run.lua' </dev/null

# Run the tests and write every snapshot they compare with anew.
snapshot filter="":
    LESE_UPDATE_SNAPSHOTS=1 just test "$1"

# Run a picker of test/custom.lua headlessly on Neovim and Vim and fail when they differ.
run *args:
    {{quote(lese)}}/bin/lese-run --host=both --rtp . --custom test/custom.lua "$@"

# Run the mrw picker on both editors against the stand-in vim-mr in
# test/fixture, whose lists do not depend on the editing history of the machine.
# Windows CI has no Vim to compare with.
run-check:
    {{ if os_family() == "windows" { "echo 'run-check: skipped; Windows runs Neovim only'" } else { "just run mrw --rtp test/fixture/vim-mr --query lic" } }}

# Everything CI runs.
ci: fmt-check lint test run-check
