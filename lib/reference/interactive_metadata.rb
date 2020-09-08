module Reference
  class InteractiveMetadata
    attr_reader :extra_metadata

    def initialize(stdin: $stdin, stdout: $stdout, templates: Config.instance.reference_templates)
      @stdin = stdin
      @stdout = stdout
      @templates = templates
      @extra_metadata = {}
      @prompt = TTY::Prompt.new(input: stdin, output: stdout)
    end

    def call(path:, noninteractive_metadata:)
      extra_metadata.clear
      run(path, noninteractive_metadata)
    end

    def run(path, noninteractive_metadata)
      @stdout.puts "==[ #{path} ]".ljust(75, '=')

      prompt_for_delete_after_ingestion(noninteractive_metadata.delete_after_ingestion?)
      defaults = prompt_for_template(noninteractive_metadata)
      prompt_for_title(defaults.title)
      prompt_for_dated(defaults.dated)
      prompt_for_author(defaults.author)
      prompt_for_notes(defaults.notes)
      prompt_for_tags(defaults.tags)

      defaults.with(extra_metadata)
    end

    private

      def prompt_for_delete_after_ingestion(default)
        answer = @prompt.yes?("Delete after ingestion?", default: default)
        extra_metadata[:delete_after_ingestion?] = answer
        nil
      end

      def prompt_for_template(noninteractive_metadata)
        return noninteractive_metadata if @templates.empty?

        answer = @prompt.select("Template:") do |menu|
          menu.choice('None', false)
          @templates.each_with_index { menu.choice(_1.name, _2) }
        end

        if answer
          @templates[answer].apply_to(noninteractive_metadata)
        else
          noninteractive_metadata
        end
      end

      def prompt_for_title(default_title)
        extra_metadata[:title] = @prompt.ask('Title:') do
          _1.value(default_title)
          _1.modify(:strip)
        end
      end

      def prompt_for_dated(default_dated)
        answer = @prompt.ask('Dated:') do |q|
          q.required(true)
          q.value(default_dated&.iso8601)
          q.validate { _1.empty? || HumanDateParser.new.(_1) }
        end

        extra_metadata[:dated] =
          if answer
            HumanDateParser.new.(answer)
          else
            nil
          end
      end

      def prompt_for_author(default_author)
        extra_metadata[:author] = @prompt.ask('Author:', value: default_author)
      end

      def prompt_for_notes(default_note)
        extra_metadata[:notes] = @prompt.ask('Notes:', value: default_note)
      end

      def prompt_for_tags(default_tags)
        str_defaults = (default_tags || []).map{ '#' + _1 }.join(' ')
        raw_tags = @prompt.ask("Tags:", value: str_defaults)
        tags = (raw_tags || "").strip.split.map { _1.delete_prefix('#') }.reject(&:empty?)
        extra_metadata[:tags] = tags if tags.any?
      end
  end
end
