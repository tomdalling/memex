module Memex
  ROOT_DIR = Pathname.new(__dir__).parent.freeze
  CONFIG_PATH = ROOT_DIR / 'config.yml'
  VIM_RUNTIME_DIR = ROOT_DIR / "config"

  extend self

  def volume_root_dir
    Config.memex.volume_path
  end

  def data_dir
    volume_root_dir / "data"
  end

  def zettel_dir
    data_dir / "zettel"
  end

  def journal_dir
    data_dir / "journal"
  end

  def wiki_dir
    data_dir / "wiki"
  end

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
