let s:zettel_cmd = "../../bin/zettel.rb"
let g:zettel#link_regex = '\v\[\[([a-zA-Z0-9_-]{3})\]\]'

function! s:edit_list_item(item)
  let l:path = split(a:item)[0]
  execute 'edit' l:path
endfunction

function! s:zettel_new(title, in_current_buffer)
  let l:title = (a:title == "" ? "" : shellescape(a:title))
  let l:path = system(s:zettel_cmd . " new --then=print-path " . l:title)
  if a:in_current_buffer
    execute 'edit' l:path
  else
    execute 'vsplit' l:path
  end
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

function! s:complete_link()
  let l:pos = getpos('.')
  let l:prev_text = matchstr(strpart(getline(l:pos[1]), 0, l:pos[2]-1), '\v[\[(]$')
  let l:reducers = {
    \ "[": function('s:reduce_to_full_link'),
    \ "(": function('s:reduce_to_link_path'),
    \ }

  if has_key(l:reducers, l:prev_text)
    return fzf#vim#complete(fzf#vim#with_preview({
      \ 'source': s:zettel_cmd . ' list',
      \ 'prefix': '',
      \ 'reducer': l:reducers[l:prev_text],
      \ 'options': ['--delimiter=\\t', '--with-nth=2,3'],
      \ 'placeholder': '{1}',
      \}))
  else
    " default behaviour of tab
    " TODO: it would be better to not hard-code VimCompletesMe
    return VimCompletesMe#vim_completes_me(0)
  endif
endfunction

" only handles single item atm
function! s:reduce_to_full_link(items)
  let l:zettel = s:parse_list_item(a:items[0])
  return l:zettel.title . '](' . l:zettel.path . ')'
endfunction

" only handles single item atm
function! s:reduce_to_link_path(items)
  let l:zettel = s:parse_list_item(a:items[0])
  return l:zettel.path . ')'
endfunction

function! s:parse_list_item(list_item)
  let l:parts = split(a:list_item, '\t')
  return { 'path': l:parts[0], 'id': l:parts[1], 'title': l:parts[2] }
endfunction

command! -bang ZettelOpen call <sid>zettel_open(<bang>0)
command! -bang -nargs=* ZettelNew call <sid>zettel_new(<q-args>, <bang>0)
command! -bang -nargs=* ZettelGrep call <sid>zettel_grep(<q-args>, <bang>0)

nnoremap <leader>. :ZettelOpen<cr>

" hijack VimCompletesMe tab function to intercept with our own
inoremap <expr> <plug>vim_completes_me_forward  <sid>complete_link()
