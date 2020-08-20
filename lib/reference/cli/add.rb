module Reference
  class CLI::Add < Dry::CLI::Command
    desc "Ingests files into the reference section of the memex"
    option :tags, type: :array, desc: "Tags to apply to the file"
    argument :files, type: :array, required: true, desc: "The files to ingest"

    def initialize(
      file_system: FileSystem,
      config: Config.instance,
      random: Random.new,
      now: Time.method(:now),
      fulltext_extractor: FulltextExtractor
    )
      @file_system = file_system
      @config = config
      @random = random
      @now = now
      @fulltext_extractor = fulltext_extractor
    end

    def call(files:, tags: [])
      files.each do |input_path|
        run(input_path: Pathname(input_path), tags: tags)
      end
    end

    private

      BASENAME_LEN = 4
      VALID_FILENAME_CHARS = ('a'..'z').to_a + ('0'..'9').to_a

      def run(input_path:, tags:)
        ref_path = random_new_ref_path(input_path.extname)
        @file_system.copy(input_path, ref_path)
        write_metadata(ref_path, input_path, tags)
        write_fulltext(ref_path)
      end

      def random_new_ref_path(ext)
        500.times do
          path = @config.reference_dir.join(random_basename).sub_ext(ext)
          return path unless @file_system.exists?(path)
        end

        fail "Couldn't generate new unique reference path"
      end

      def random_basename
        "".tap do |basename|
          BASENAME_LEN.times do
            idx = @random.rand(VALID_FILENAME_CHARS.size)
            basename << VALID_FILENAME_CHARS[idx]
          end
        end
      end

      def write_metadata(ref_path, original_path, tags)
        @file_system.write(
          ref_path.sub_ext('.metadata.yml'),
          YAML.dump(deep_yamlify({
            added_at: @now.().iso8601,
            original_filename: original_path.basename,
            tags: tags,
          }))
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
