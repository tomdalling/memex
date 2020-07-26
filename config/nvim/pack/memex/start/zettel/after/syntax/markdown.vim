exe "syn match zettelLink '" . g:zettel#link_regex . "' containedin=ALL contained"
syn match zettelHashtag '#[a-z0-9-_]\+' containedin=ALL contained

hi def link zettelLink htmlLink
hi def link zettelHashtag Type
