module Reference
  class CLI::Add < Dry::CLI::Command
    desc "Ingests files into the reference section of the memex"
    option :tags, type: :array, desc: "Tags to apply to the file"
    argument :files, type: :array, required: true, desc: "The files to ingest"

    def initialize(
      file_system: FileSystem,
      config: Config.instance,
      now: Time.method(:now),
      fulltext_extractor: FulltextExtractor
    )
      @file_system = file_system
      @config = config
      @now = now
      @fulltext_extractor = fulltext_extractor
    end

    def call(files:, tags: nil)
      files.map{ Pathname(_1) }.each do |input_path|
        metadata = metadata_for(input_path, tags)
        add_document(input_path, metadata)
      end
    end

    private

      BASENAME_LEN = 4
      VALID_FILENAME_CHARS = ('a'..'z').to_a + ('0'..'9').to_a

      def metadata_for(original_path, tags)
        {}.tap do |metadata|
          metadata[:added_at] = @now.().iso8601
          metadata[:original_filename] = original_path.basename
          metadata[:tags] = tags if tags
        end
      end

      def add_document(input_path, metadata)
        ref_path = generate_ref_path(input_path.extname)
        @file_system.copy(input_path, ref_path)
        write_metadata(ref_path, metadata)
        write_fulltext(ref_path)
      end

      def generate_ref_path(ext)
        date = @now.().to_date.iso8601
        (1..).each do |suffix|
          basename = "#{date}_#{suffix.to_s.rjust(3, '0')}"
          unless basename_exists?(basename)
            return @config.reference_dir.join(basename).sub_ext(ext)
          end
        end
      end

      def basename_exists?(basename)
        @file_system.children_of(@config.reference_dir).any? do
          _1.basename.to_s.start_with?(basename)
        end
      end

      def write_metadata(ref_path, metadata)
        @file_system.write(
          ref_path.sub_ext('.metadata.yml'),
          YAML.dump(deep_yamlify(metadata)),
        )
      end

      def write_fulltext(ref_path)
        @file_system.write(
          ref_path.sub_ext('.fulltext.txt'),
          @fulltext_extractor.(path: ref_path, file_system: @file_system),
        )
      end

      def deep_yamlify(obj)
        case obj
        when String then obj
        when Symbol then obj.to_s
        when Pathname then obj.to_path
        when Hash then obj.to_h { [deep_yamlify(_1), deep_yamlify(_2)] }
        when Enumerable then obj.map { deep_yamlify(_1) }
        else fail "Can't yamlify: #{obj.inspect}"
        end
      end
  end
end
