let s:zettel_cmd = "../../bin/zettel"
let g:zettel#link_regex = '\v\[\[([a-zA-Z0-9_-]{3})\]\]'

function! s:edit_list_item(args)
  let l:action = a:args[0]
  let l:item = a:args[1]
  let l:path = split(l:item)[0]
  if l:action ==# ''
    execute 'edit' l:path
  elseif l:action ==# 'ctrl-v'
    execute 'vsplit' l:path
  else
    echom 'Unhandled action: ' . l:action
  endif
endfunction

function! s:zettel_new(title, in_current_buffer, use_selection)
  let l:old_z = @z

  " get the title to feed into the `bin/zettel new` CLI
  if a:use_selection
    " yank selected text into @z
    normal! gv"zy
    let l:title = trim(@z . ' ' . a:title)
  else
    let l:title = a:title
  endif

  " make a new zettel and get the path
  let l:path = trim(system(s:zettel_cmd." new --then=print-path ".shellescape(l:title)))

  " replace selected text with link to new zettel
  if a:use_selection
    let @z = '['.l:title.']('.l:path.')'
    exe "normal! gvc\<c-r>z"
  endif

  " either edit the new file, or vsplit it
  if a:in_current_buffer && !&modified
    execute 'edit' l:path
  else
    execute 'vsplit' l:path
  end

  " restore previous value of @z before messing with it
  let @z = l:old_z
endfunction

function! s:zettel_open(fullscreen)
  " NOTE: the 'placeholder' option is undocumented. It's the "{}" part of the
  " preview command on the FZF command line
  let l:options = fzf#wrap(fzf#vim#with_preview({
    \ 'source': s:zettel_cmd . ' list',
    \ 'options': ['--delimiter=\\t', '--with-nth=2,3'],
    \ 'placeholder': '{1}',
    \ }))

  " overwrite the sink function. This needs to be done AFTER fzf#wrap, because
  " if a sink is present, fzf#wrap does not include the proper options for
  " opening files with ctrl-v
  let l:options['sink*'] = function('s:edit_list_item')

  call fzf#vim#files('', l:options, a:fullscreen)
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
command! -bang -range -nargs=* ZettelNew call <sid>zettel_new(<q-args>, <bang>0, <range>)
command! -bang -nargs=* ZettelGrep call <sid>zettel_grep(<q-args>, <bang>0)

nnoremap <leader>. :ZettelOpen<cr>

" hijack VimCompletesMe tab function to intercept with our own
inoremap <expr> <plug>vim_completes_me_forward  <sid>complete_link()
