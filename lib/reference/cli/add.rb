module Reference
  class CLI::Add < Dry::CLI::Command
    desc "Ingests files into the reference section of the memex"
    option :tags, type: :array, desc: "Tags to apply to the file"
    option :interactive, type: :bool, desc: "Prompt for metadata interactively"
    argument :files, type: :array, required: true, desc: "The files to ingest"

    def initialize(
      file_system: FileSystem,
      config: Config.instance,
      now: Time.method(:now),
      fulltext_extractor: FulltextExtractor,
      interactive_metadata: nil,
      stdout: $stdout
    )
      @file_system = file_system
      @config = config
      @now = now
      @fulltext_extractor = fulltext_extractor
      @stdout = stdout
      @interactive_metadata = interactive_metadata || InteractiveMetadata.new(stdout: stdout)
    end

    def call(files:, tags: nil, interactive: true)
      files.map{ Pathname(_1) }.each do |input_path|
        metadata = metadata_for(
          original_path: input_path,
          tags: tags,
          interactive: interactive,
        )
        ref_path = add_document(input_path, metadata)
        puts ">>> Ingested \"#{ref_path}\" from \"#{input_path}\""
      end
    end

    private

      BASENAME_LEN = 4
      VALID_FILENAME_CHARS = ('a'..'z').to_a + ('0'..'9').to_a

      def puts(...)
        @stdout.puts(...)
      end

      def metadata_for(original_path:, tags:, interactive:)
        noninteractive = Metadata.new(
          added_at: @now.(),
          original_filename: original_path.basename.to_s,
          tags: tags,
        )

        if interactive
          @interactive_metadata.(
            path: original_path,
            noninteractive_metadata: noninteractive,
          )
        else
          noninteractive
        end
      end

      def add_document(input_path, metadata)
        generate_ref_path(input_path.extname).tap do |ref_path|
          @file_system.copy(input_path, ref_path)
          write_metadata(ref_path, metadata)
          write_fulltext(ref_path)
        end
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
        @file_system.write(ref_path.sub_ext('.metadata.yml'), metadata.to_yaml)
      end

      def write_fulltext(ref_path)
        @file_system.write(
          ref_path.sub_ext('.fulltext.txt'),
          @fulltext_extractor.(path: ref_path, file_system: @file_system),
        )
      end
  end
end
