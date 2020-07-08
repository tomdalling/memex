command! -bang ZettleOpen call fzf#vim#grep(
  \ '../bin/zettle.rb list',
  \ 0,
  \ fzf#vim#with_preview(),
  \ <bang>0
  \ )
