#!/usr/bin/env ruby

require_relative '_bootstrap'
require 'date'

module Journal
  extend self

  def edit_date(date)
    path = Memex::JOURNAL_DIR / date.strftime('%F.md')
    title = date.strftime('%A, %-d %B %Y')
    template = <<~END_TEMPLATE
      #{title}
      #{'=' * title.length}


    END_TEMPLATE

    unless path.exist?
      path.write(template, mode: 'wx') # never overwrites
    end

    system(
      'nvim',
      '-c', 'normal G$',
      '--', path.to_path,
      chdir: Memex::JOURNAL_DIR,
    )

    if path.read.strip == template.strip
      puts "Deleting journal entry due to being empty: #{path}"
      path.delete # don't leave behind empty journals
    end
  end
end

module Journal::CLI
  extend Dry::CLI::Registry

  class Today < Dry::CLI::Command
    desc "Opens the journal entry for today, creating it if it doesn't exist"

    def call
      Journal.edit_date(Date.today)
    end
  end

  class Yesterday < Dry::CLI::Command
    desc "Opens the journal entry for yesterday, creating it if it doesn't exist"

    def call
      Journal.edit_date(Date.today - 1)
    end
  end

  class Tomorrow < Dry::CLI::Command
    desc "Opens the journal entry for tomorrow, creating it if it doesn't exist"

    def call
      Journal.edit_date(Date.today + 1)
    end
  end

  register "today", Today
  register "yesterday", Yesterday
  register "tomorrow", Tomorrow
end


ARGV << "today" if ARGV.empty?
Dry::CLI.new(Journal::CLI).call
