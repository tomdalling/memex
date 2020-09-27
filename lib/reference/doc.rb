module Reference
  class Doc
    attr_reader :id

    extend Forwardable
    def_delegators :metadata, *%i(original_filename title tags)

    def initialize(id)
      @id = id
    end

    def metadata
      @metadata ||= begin
        Metadata.from_yaml(metadata_path.read)
      end
    end

    def metadata_path
      base_path.sub_ext('.metadata.yml')
    end

    def path
      base_path.sub_ext(File.extname(original_filename))
    end

    def exists?
      metadata_path.exist?
    end

    private

      def base_path
        Config.instance.reference_dir / id
      end
  end
end
