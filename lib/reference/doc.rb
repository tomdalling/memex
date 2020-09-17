module Reference
  class Doc
    attr_reader :id

    def initialize(id)
      @id = id
    end

    def metadata
      @metadata ||= begin
        path = Config.instance.reference_dir.join(id).sub_ext('.metadata.yml')
        Metadata.from_yaml(path.read)
      end
    end

    extend Forwardable
    def_delegators :metadata, *%i(original_filename title tags)
  end
end
