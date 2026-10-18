" A stand-in for vim-mr's mrd list with fixed directories of this
" repository, so `just run` shows the same on every machine.
function! mr#mrd#list() abort
  return map(['.', 'lua', 'test'], { _, v -> fnamemodify(v, ':p:h') })
endfunction

function! mr#mrd#delete(filename) abort
endfunction
