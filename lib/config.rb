class Config
  class MemexConfig
    value_semantics do
      image_path Pathname, coerce: Pathname.method(:new)
      volume_path Pathname, coerce: Pathname.method(:new)
    end
  end

  value_semantics do
    memex MemexConfig,
      coerce: MemexConfig.coercer
    reference_templates ArrayOf(Reference::Template),
      default: [],
      coerce: ArrayCoercer(Reference::Template.coercer)
  end

  class << self
    extend Forwardable
    def_delegators :instance, *%i(memex)

    def instance
      @instance ||= begin
        yml = Memex::CONFIG_PATH.read
        attrs = YAML.safe_load(yml, symbolize_names: true)
        new(attrs)
      rescue => ex
        fail "Failed to load #{Memex::CONFIG_PATH}: #{ex}"
      end
    end
  end

  def volume_root_dir
    memex.volume_path
  end

  def reference_dir
    volume_root_dir / "ref"
  end

  def zettel_dir
    volume_root_dir / "zettel"
  end

  def journal_dir
    volume_root_dir / "journal"
  end

  def wiki_dir
    volume_root_dir / "wiki"
  end
end
