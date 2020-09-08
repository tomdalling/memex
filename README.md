Memex
=====

This is a work-in-progress personal project. I might write about it if it
actually works for me. Time will tell.

![Screenshot of this project running](doc/example.png)


Zettel
------

From Vim:

 - [X] `:ZettelNew` Create new zettel, optionally linking highlighted text
 - [X] `:ZettelOpen` Fuzzy find zettel based on title
 - [ ] `:ZettelOpenRecent` (like FZFMru)
 - [X] `:ZettelGrep` Full text search for zettel
   - [ ] Handle zero results case (it's doing some weird error)
 - [X] `:ZettelBacklinks` Load back-linking zettels into the quickfix list
 - [X] Tab-based zettel link auto-completion
 - [X] `<c-]>` or `gf` jumps to linked files
 - [X] Syntax highlighting for hashtags

From command line:

 - [X] `bin/zettel new` opens Vim in a new zettel
 - [X] `bin/zettel open` opens Vim to an existing zettel or to `:ZettelOpen`
 - [X] `bin/zettel list` lists all zettels
   - [X] `--hastags '#a && #b'` filter by hashtag query
   - [X] `--backlinking-to x0r` filter by back-links
 - [ ] `bin/zettel tags` for listing all tags
 - [ ] `bin/zettel rename-tags` for updating tags across all zettel

Journal
-------

 - [X] `bin/journal today` opens Vim to today's journal, creating it if needed
 - [X] `bin/journal yesterday` opens Vim to yesterday's journal, creating it if needed
 - [X] Auto-delete new files if they haven't been edited

Wiki
----

Linked markdown files.

 - [X] `bin/wiki open` opens Vim to given page or `index`
 - [X] `bin/wiki export` exports a page as a standalone HTML file

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

 - [X] `bin/memex mount` mounts the encrypted volume
 - [X] `bin/memex eject` ejects the encrypted volume, committing changes to git
 - [X] `bin/memex run` mounts, runs a script, then ejects
 - [X] auto-updates itself from the master copy inside the encrypted volume

Tests
-----

Use `bin/test` as a stand-in for the `bench` command. In test.vim:


```vim
let test#ruby#testbench#executable = 'bin/test'
```

Mapping for manual tests:

```vim
nnoremap <leader>tm :tabnew term://bundle exec ruby test/manual/reference/interactive_metadata.rb<cr>
```
