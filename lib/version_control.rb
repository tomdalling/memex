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
    changed_paths = changes.map(&:path).select { File.extname(_1) == ".md" }
    cloud = word_cloud(changed_paths)

    if changes.size == 1
      ch = changes.first
      return "#{ch.verb.capitalize} #{ch.path}\n\n#{cloud}"
    end

    dir_stat = Memex.sh("git diff --cached --dirstat=files")
    if dir_stat.strip.lines.size == 1
      dir = dir_stat.strip.partition(' ').last
      return "Updated #{changes.size} files in #{dir}\n\n#{cloud}"
    end

    summary = Memex.sh("git diff --cached --shortstat").strip
    "#{summary}\n\n#{cloud}"
  end

  def changes
    # NOTE: not _necessarily_ safe to memoize, but it works at the moment
    @changes ||= Memex.sh("git diff --cached --name-status").lines.map do
      status, path = _1.split(/\s+/, 2).map(&:strip)
      Change.new(path: path, status: status)
    end
  end

  # Sort words in selection: !ruby -e "puts STDIN.read.split.map(&:strip).uniq.sort.join(' ')"
  COMMON_WORDS = Set.new(%w(
    a about actually after again all also am an and any are around as at back
    bad be because been being bit but by can could did didn't do doing don't
    even feel few first for from get go going good got guess had has have he
    her how i'm i've if in into is it it's just know last like made make maybe
    me might more much my need new no not now of on one only or other out over
    probably really see she should so some something still than that that's the
    them then there these they things think this though to today too up very
    want was way we well what when where which while who will with would you
  ))

  GIT_COMMIT_MESSAGE_BODY_WIDTH = 72

  def most_frequent_words(file_paths)
    # NOTE: this could easily be optimised if needed
    file_paths
      .flat_map { File.read(_1).split(/(\s|[\[\]()])+/) }
      .map(&:downcase)
      .select { _1.match?(/[a-z]/) }
      .reject { _1.match?(/[a-z0-9]{3}\.md/) }
      .map { _1.tr('’“”', "'\"\"") }
      .map { strip_regex(_1, /[.,?:()"\[\]]+/) }
      .reject { COMMON_WORDS.include?(_1) }
      .select { _1.length >= 2 }
      .tally
      .sort_by(&:last)
      .last(30)
      .reverse
      .to_h
  end

  def word_cloud(file_paths)
    words = most_frequent_words(file_paths).keys
    return "No markdown changes detected" if words.empty?

    lines = ["Most common words:"]
    words.each do |word|
      if lines.empty?
        lines << word
      else
        possible_line = lines.last + ' ' + word
        if possible_line.length <= GIT_COMMIT_MESSAGE_BODY_WIDTH
          lines[-1] = possible_line
        else
          lines << word
        end
      end
    end

    lines.join("\n") + "\n"
  end

  def strip_regex(str, regex)
    prefix = str.match(Regexp.new('\A' + regex.to_s))
    if prefix
      str = str[prefix.end(0)..]
    end

    suffix = str.match(Regexp.new(regex.to_s + '\z'))
    if suffix
      str = str[0...suffix.begin(0)]
    end

    str
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
