module Memex
  ROOT_DIR = Pathname.new(__dir__).parent.freeze
  VIM_RUNTIME_DIR = ROOT_DIR / "config"

  DATA_DIR = ROOT_DIR / "data"
  ZETTEL_DIR = DATA_DIR / "zettel"
  JOURNAL_DIR = DATA_DIR / "journal"
  WIKI_DIR = DATA_DIR / "wiki"

  def self.sh(*args)
    parts = args.select { _1.is_a?(String) }
    pretty_cmd = parts.size > 1 ? Shellwords.join(parts) : parts.first
    puts "Running: #{pretty_cmd}"

    output, status = Open3.capture2e(*args)
    unless status.success?
      abort("!!! Command failed! Output: \n#{output}")
    end

    output
  end
end
