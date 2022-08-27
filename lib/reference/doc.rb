module Reference
  class Doc
    attr_reader :id

    extend Forwardable
    def_delegators :metadata, *%i(original_filename title tags)

    # TODO: this is a temporary shim while migrating to Nodoor
    def self.for_nodoor_record(nodoor_record)
      new(nodoor_record.path.sub_ext('').to_s, nodoor_record: nodoor_record)
    end

    def initialize(id, nodoor_record: nil)
      raise ArgumentError unless id.is_a?(String)
      @id = id
      @nodoor_record = nodoor_record
    end

    def metadata
      @metadata ||= begin
        if nodoor_record
          Metadata.from_hash(nodoor_record.metadata)
        else
          Metadata.from_yaml(metadata_path.read)
        end
      end
    rescue ValueSemantics::MissingAttributes
      pp self
      raise
    end

    def metadata_path
      # TODO: this is too low-level. Metadata reading/writing should be
      # encapsulated at the repository level
      base_path.sub_ext(path.extname + Nodoor::Repo::SIDECAR_METADATA_EXT)
    end

    def path
      base_path.sub_ext(File.extname(original_filename))
    end

    def exists?
      metadata_path.exist?
    end

    private

      attr_reader :nodoor_record

      def base_path
        Config.instance.reference_dir / id
      end
  end
end
