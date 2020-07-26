let s:zettel_cmd = "../bin/zettel.rb"
let g:zettel#link_regex = '\v\[\[([a-zA-Z0-9_-]{3})\]\]'

function! s:edit_list_item(item)
  let l:path = split(a:item)[0]
  execute 'edit' l:path
endfunction

function! s:reduce_list_items_to_link(items)
  " only handles single item atm
  let l:id = split(a:items[0])[1]
  return l:id . ']] '
endfunction

function! s:zettel_new(title)
  let l:title = (a:title == "" ? "" : shellescape(a:title))
  let l:path = system(s:zettel_cmd . " new --then=print-path " . l:title)
  execute 'edit' l:path
endfunction

function! s:zettel_open(bang)
  let l:cmd = s:zettel_cmd . ' list'
  " NB: the 'placeholder' option is undocumented. It's the "{}" part of the
  " preview command on the FZF command line
  let l:options = fzf#vim#with_preview({
    \ 'options': ['--delimiter=\\t', '--with-nth=2,3'],
    \ 'placeholder': '{1}',
    \ 'sink': function('s:edit_list_item'),
    \ })
  call fzf#vim#grep(l:cmd, 0, l:options, a:bang)
endfunction

function! s:zettel_grep(qargs, bang)
  let l:cmd_args = [
    \'rg',
    \'--no-ignore-vcs',
    \'--smart-case',
    \'--column',
    \'--line-number',
    \'--no-heading',
    \'--color=always',
    \]
  let l:cmd = join(l:cmd_args, " ") . " " . shellescape(a:qargs)
  call fzf#vim#grep(l:cmd, 1, fzf#vim#with_preview(), a:bang)
endfunction

function! s:zettel_tag(tag)
  let l:match = matchlist(a:tag, g:zettel#link_regex)
  if l:match == []
    " try do default behaviour of c-]
    exe 'tag' a:tag
  else
    let l:fname = l:match[1] . '.md'
    write
    execute 'edit' l:fname
  endif
endfunction

function! s:complete_link()
  let l:pos = getpos('.')
  let l:prev_text = matchstr(strpart(getline(l:pos[1]), 0, l:pos[2]-1), "[^ \t]*$")
  if l:prev_text == "[["
    return fzf#vim#complete(fzf#vim#with_preview({
      \ 'source': s:zettel_cmd . ' list',
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

command! -bang ZettelOpen call <sid>zettel_open(<bang>0)
command! -nargs=* ZettelNew call <sid>zettel_new(<q-args>)
command! -bang -nargs=* ZettelGrep call <sid>zettel_grep(<q-args>, <bang>0)
command! -nargs=1 ZettelTag call <sid>zettel_tag(<q-args>)

nnoremap <leader>. :ZettelOpen<cr>
nnoremap <C-]> :exe 'ZettelTag' expand("<cWORD>")<cr>
" hijack VimCompletesMe tab function to intercept with our own
inoremap <expr> <plug>vim_completes_me_forward  <sid>complete_link()
