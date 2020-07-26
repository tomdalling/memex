#!/usr/bin/env ruby

require_relative '_bootstrap'

module VersionControl
  extend self

  def commit(message: nil)
    Dir.chdir(Memex::DATA_DIR)

    Memex.sh('git add --all')
    if changes.empty?
      puts "No changes. Skipping commit."
    else
      Memex.sh('git', 'commit', '-m', message || default_message)
    end
  end

  def default_message
    if changes.size == 1
      ch = changes.first
      return "#{ch.verb.capitalize} #{ch.path}"
    end

    dir_stat = Memex.sh("git diff --cached --dirstat=files")
    if dir_stat.strip.lines.size == 1
      dir = dir_stat.strip.partition(' ').last
      return "Updated #{changes.size} files in #{dir}"
    end

    summary = Memex.sh("git diff --cached --shortstat").strip
    summary + "\n\n" + dir_stat
  end

  def changes
    # NOTE: not _necessarily_ safe to memoize, but it works at the moment
    @changes ||= Memex.sh("git diff --cached --name-status").lines.map do
      status, path = _1.split(/\s+/, 2).map(&:strip)
      Change.new(path: path, status: status)
    end
  end

  class Change
    include ValueSemantics.for_attributes {
      path String
      status String
    }

    STATUSES = {
      "A" => "Added",
      "C" => "Copied",
      "D" => "Deleted",
      "M" => "Modified",
      "R" => "Renamed",
      "T" => "Changed",
      "U" => "Unmerged",
      "X" => "???",
      "B" => "Broke?",
    }

    def verb
      status
        .chars
        .map { STATUSES.fetch(_1, _1) }
        .join("/")
    end
  end
end

module VersionControl::CLI
  extend Dry::CLI::Registry

  class Commit < Dry::CLI::Command
    desc "Commits all changes to the data directory"
    option :m, desc: "Git commit message"

    def call(m: nil)
      VersionControl.commit(message: m)
    end
  end

  register "commit", Commit
end


Dry::CLI.new(VersionControl::CLI).call
