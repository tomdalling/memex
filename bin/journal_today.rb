#!/usr/bin/env ruby

require 'pathname'

NOW = Time.now
JOURNAL_DIR = Pathname(__dir__) / ".." / "journal"
JOURNAL_PATH = JOURNAL_DIR / NOW.strftime('%F.md')
VIMRC_PATH = JOURNAL_DIR / 'vimrc'

title = NOW.strftime('%A, %-d %B %Y')
template = <<~END_TEMPLATE
  #{title}
  #{'=' * title.length}


END_TEMPLATE

unless JOURNAL_PATH.exist?
  JOURNAL_PATH.write(template, mode: 'wx') # never overwrites
end

Dir.chdir(JOURNAL_DIR)
system('nvim', JOURNAL_PATH.to_path, '-c', 'normal G$', '-S', VIMRC_PATH.to_path)

if JOURNAL_PATH.read.strip == template.strip
  puts "Deleting journal entry due to being empty: #{JOURNAL_PATH}"
  JOURNAL_PATH.delete # don't leave behind empty journals
end
