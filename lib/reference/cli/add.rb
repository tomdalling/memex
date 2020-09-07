module Reference
  class CLI::Add < Dry::CLI::Command
    desc "Ingests files into the reference section of the memex"
    option :interactive, type: :boolean, default: true, desc: "Prompt for metadata interactively"
    option :tags, type: :array, desc: "The 'tags' metadata value"
    option :author, type: :string, desc: "The 'author' metadata value"
    option :notes, type: :string, desc: "The 'notes' metadata value"
    option :title, type: :string, dest: "The 'title' metadata value"
    option :template, type: :string, desc: "A metadata template name from the config"
    argument :files, type: :array, required: true, desc: "The files to ingest"

    def initialize(
      file_system: FileSystem,
      config: Config.instance,
      now: Time.method(:now),
      interactive_metadata: nil,
      stdout: $stdout
    )
      @file_system = file_system
      @config = config
      @now = now
      @stdout = stdout
      @interactive_metadata = interactive_metadata || InteractiveMetadata.new(stdout: stdout)
    end

    def call(
      files:,
      interactive: true,
      args: [],
      template: nil,
      **metadata_options
    )
      files.map{ Pathname(_1) }.each do |input_path|
        metadata = metadata_for(
          template_name: template,
          original_path: input_path,
          interactive: interactive,
          metadata_options: metadata_options,
        )

        ref_path = add_document(input_path, metadata)
        puts ">>> Ingested \"#{ref_path}\" from \"#{input_path}\""

        if metadata.delete_after_ingestion?
          @file_system.delete(input_path)
          puts "--- Deleted \"#{input_path}\""
        end
      end
    end

    private

      BASENAME_LEN = 4
      VALID_FILENAME_CHARS = ('a'..'z').to_a + ('0'..'9').to_a

      def puts(...)
        @stdout.puts(...)
      end

      def metadata_for(original_path:, interactive:, metadata_options:, template_name:)
        Metadata
          .new(original_filename: original_path.basename.to_s, added_at: @now.())
          .then { apply_template(_1, template_name) }
          .with(metadata_options)
          .then { apply_interactive(_1, interactive, original_path) }
      end

      def apply_template(metadata, template_name)
        return metadata unless template_name

        template = @config.reference_templates.find { _1.name == template_name }
        if template
          template.apply_to(metadata)
        else
          fail "Template not found: #{template_name}"
        end
      end

      def apply_interactive(metadata, is_interactive, original_path)
        if is_interactive
          @interactive_metadata.(
            path: original_path,
            noninteractive_metadata: metadata,
          )
        else
          metadata
        end
      end

      def add_document(input_path, metadata)
        generate_ref_path(input_path.extname, metadata.dated).tap do |ref_path|
          @file_system.copy(input_path, ref_path)
          write_metadata(ref_path, metadata)
        end
      end

      def generate_ref_path(ext, dated)
        base_path = Reference.unused_document_base_path(
          dated || @now.().to_date,
          file_system: @file_system,
          config: @config,
        )
        base_path.sub_ext(ext)
      end

      def write_metadata(ref_path, metadata)
        @file_system.write(ref_path.sub_ext('.metadata.yml'), metadata.to_yaml)
      end
  end
end
