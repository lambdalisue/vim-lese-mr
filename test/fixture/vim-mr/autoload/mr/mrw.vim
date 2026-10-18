" A stand-in for vim-mr's mrw list with fixed files of this repository, so
" `just run` shows the same on every machine.
function! mr#mrw#list() abort
  return map(['LICENSE', 'justfile', 'flake.nix'], { _, v -> fnamemodify(v, ':p') })
endfunction

function! mr#mrw#delete(filename) abort
endfunction
