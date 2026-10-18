" A stand-in for vim-mr's mrr list with fixed directories of this
" repository, so `just run` shows the same on every machine.
function! mr#mrr#list() abort
  return map(['.', 'lua', 'test'], { _, v -> fnamemodify(v, ':p:h') })
endfunction

function! mr#mrr#delete(filename) abort
endfunction
