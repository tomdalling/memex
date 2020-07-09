set nowrap
set textwidth=80

let s:zettle_cmd = "../bin/zettle.rb"

function! s:edit_list_item(item)
  let l:path = split(a:item)[0]
  execute 'edit' l:path
endfunction

function! s:reduce_list_items_to_link(items)
  " only handles single item atm
  let l:id = split(a:items[0])[1]
  return l:id . ']] '
endfunction

function! s:zettle_new(title)
  let l:title = (a:title == "" ? "" : shellescape(a:title))
  let l:path = system(s:zettle_cmd . " new --then=print-path " . l:title)
  execute 'edit' l:path
endfunction

function! s:complete_link()
  let l:pos = getpos('.')
  let l:prev_text = matchstr(strpart(getline(l:pos[1]), 0, l:pos[2]-1), "[^ \t]*$")
  if l:prev_text == "[["
    return fzf#vim#complete(fzf#vim#with_preview({
      \ 'source': s:zettle_cmd . ' list',
      \ 'prefix': '',
      \ 'reducer': function('s:reduce_list_items_to_link'),
      \ 'options': ['--delimiter=\\t', '--with-nth=2,3'],
      \ 'placeholder': '{1}',
      \}))
  else
    " default behaviour of tab
    return VimCompletesMe#vim_completes_me(0)
  endif
endfunction

" NB: the 'placeholder' option is undocumented. It's the "{}" part of the
" preview command
command! -bang ZettleOpen call fzf#vim#grep(
  \ s:zettle_cmd . ' list',
  \ 0,
  \ fzf#vim#with_preview({
    \ 'options': ['--delimiter=\\t', '--with-nth=2,3'],
    \ 'placeholder': '{1}',
    \ 'sink': function('<sid>edit_list_item'),
    \ }),
  \ <bang>0
  \ )

command! -nargs=* ZettleNew call <sid>zettle_new(<q-args>)

" hijack VimCompletesMe tab function to intercept with our own
inoremap <expr> <plug>vim_completes_me_forward  <sid>complete_link()
nnoremap <leader>. :ZettleOpen<cr>
