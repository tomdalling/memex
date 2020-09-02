let s:zettel_cmd = expand('<sfile>:p:h:h:h:h') . '/bin/zettel'
let g:zettel#link_regex = '\v\[\[([a-zA-Z0-9_-]{3})\]\]'

function! s:edit_list_item(args)
  let l:action = a:args[0]
  let l:zettel = s:parse_list_line(a:args[1])
  if l:action ==# ''
    execute 'edit' l:zettel.path
  elseif l:action ==# 'ctrl-v'
    execute 'vsplit' l:zettel.path
  else
    echom 'Unhandled action: ' . l:action
  endif
endfunction

function! s:parse_list_line(line)
  let l:parts = split(a:line, '\t')
  return {
    \ 'path': l:parts[0],
    \ 'id': l:parts[1],
    \ 'title': trim(trim(trim(l:parts[2]), '#')),
    \ }
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

function! s:qf_dict_from_vimgrep_formatted_line(idx, line)
  let [l:path, l:lnum, l:col; l:rest] = split(a:line, ':')
  return {
    \ 'filename': l:path,
    \ 'lnum': l:lnum,
    \ 'col': l:col,
    \ 'vcol': 1,
    \ 'text': join(l:rest, ':'),
    \ }
endfunction

function! s:zettel_backlinks()
  let l:zettel_id = expand('%:t:r')
  let l:cmd = [
    \ s:zettel_cmd . " list",
    \ "--backlinking-to=".shellescape(l:zettel_id),
    \ "--format=vimgrep",
    \ ]
  let l:output = trim(system(join(l:cmd, ' ')))
  let l:lines = split(l:output, "\<nl>")
  if len(l:lines) > 0
    let l:qflist = map(l:lines, function('<SID>qf_dict_from_vimgrep_formatted_line'))
    call setqflist(l:qflist)
    botright copen
  else
    echom "No backlinks found"
  endif
endfunction

function! s:complete_link()
  let l:pos = getpos('.')
  let l:prev_char = matchstr(strpart(getline(l:pos[1]), 0, l:pos[2]-1), '\v[\[(]$')

  if l:prev_char ==# '[' || l:prev_char ==# '('
    return markdown_extras#link#complete({
      \ 'source': s:zettel_cmd . ' list',
      \ 'line_parser': function('<SID>parse_list_line'),
      \ 'options': ['--delimiter=\\t', '--with-nth=2,3'],
      \ })
  else
    " default behaviour of tab
    " TODO: it would be better to not hard-code VimCompletesMe
    return VimCompletesMe#vim_completes_me(0)
  endif
endfunction

command! -bang ZettelOpen call <sid>zettel_open(<bang>0)
command! -bang -range -nargs=* ZettelNew call <sid>zettel_new(<q-args>, <bang>0, <range>)
command! -bang -nargs=* ZettelGrep call <sid>zettel_grep(<q-args>, <bang>0)
command! ZettelBacklinks call <sid>zettel_backlinks()

nnoremap <leader>. :ZettelOpen<cr>

" hijack VimCompletesMe tab function to intercept with our own
inoremap <expr> <plug>vim_completes_me_forward  <sid>complete_link()
