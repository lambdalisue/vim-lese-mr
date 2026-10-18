" A stand-in for vim-mr's mru list with fixed files of this repository, so
" `just run` shows the same on every machine.
function! mr#mru#list() abort
  return map(['LICENSE', 'justfile', 'flake.nix'], { _, v -> fnamemodify(v, ':p') })
endfunction

function! mr#mru#delete(filename) abort
endfunction
