Memex
=====

This is a work-in-progress personal project. I might write about it if it
actually works for me. Time will tell.

![Screenshot of this project running](doc/example.png)


Zettel
------

From Vim:

 - [X] ZettelNew: Create new zettel, optionally linking highlighted text
 - [X] ZettelOpen: Fuzzy find zettel based on title
 - [X] ZettelGrep: Full text search for zettel
 - [X] ZettelBacklinks: Load back-linking zettels into the quickfix list
 - [X] Tab-based zettel link autocompletion
 - [X] Ctrl-] jumps to linked files
 - [X] Syntax highlighting for hashtags
 - [X] Vim config tailored for text editing (wrapping, etc.)
 - [X] Search by hashtag (full query syntax like: #a && !#b)
 - [ ] Handle zero ZettelGrep results case (it's doing some weird error)
 - [ ] ZettelOpenRecent (like FZFMru)

From command line:

 - [X] bin/zettel.rb new: Create and edit new zettel
 - [X] Auto-delete new zettel that haven't been edited
 - [X] bin/zettel.rb open: Open vim ready to fuzzy find zettel
 - [X] List back-links to a zettel
 - [ ] Find and replace for hashtags

Journal
-------

 - [X] CLI for opening today's journal, creating the file if needed
 - [X] CLI for opening yesterday's journal, creating the file if needed
 - [X] Auto-delete new files if they haven't been edited
 - [X] Jump to previous or next entry using `[f` and `]f` (`tpope/vim-unimpared`)
 - [X] Vim config tailored for text editing (wrapping, etc.)

Wiki
----

 - It's a folder of linked markdown, yo.

TODO: References
----------------

 - links to, or copies of, external materials in an easy-to-reference
   format
 - a way to store digitised paper documents?

TODO: Todo
----------

 - A replacement for Todoist, maybe. This is turning into Org mode, man.

Memex
-----

 - [X] CLI for mounting volume
 - [X] CLI for ejecting volume
 - [X] CLI as shortcut for mounting, running script, then ejecting
 - [X] Auto commit data changes to separate git repo
 - [X] CLI auto-updates itself from the master copy inside the memex volume

