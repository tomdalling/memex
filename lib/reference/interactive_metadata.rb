module Reference
  class InteractiveMetadata
    attr_reader :extra_metadata

    def initialize(stdin: $stdin, stdout: $stdout, templates: Config.instance.reference_templates)
      @stdin = stdin
      @stdout = stdout
      @templates = templates
      @extra_metadata = {}
    end

    def call(path:, noninteractive_metadata:)
      extra_metadata.clear
      run(path, noninteractive_metadata)
    end

    def run(path, noninteractive_metadata)
      puts "==[ #{path} ]".ljust(75, '=')

      defaults = prompt_for_template(noninteractive_metadata)
      prompt_for_title(defaults)
      prompt_for_dated(defaults)
      prompt_for_author(defaults)
      prompt_for_notes(defaults)
      prompt_for_tags(defaults)

      defaults.with(extra_metadata)
    end

    private

      def prompt_for_template(noninteractive_metadata)
        return noninteractive_metadata if @templates.empty?

        loop do
          puts
          @templates.each_with_index do |tpl, idx|
            puts "  #{idx}) #{tpl.name}"
          end
          puts

          choice = prompt("Template", "no template").strip
          return noninteractive_metadata if choice.empty?

          if choice.match?(/\A\d+\z/) && Integer(choice) < @templates.size
            return @templates[Integer(choice)].apply_to(noninteractive_metadata)
          else
            puts "Not a valid template choice"
          end
        end
      end

      def prompt_for_title(defaults)
        title = prompt('Title', defaults.title).strip
        extra_metadata[:title] = title unless title.empty?
      end

      def prompt_for_dated(defaults)
        loop do
          answer = prompt('Dated', defaults.dated) { _1.iso8601 }
          break if answer.empty?

          date = HumanDateParser.new.(answer)
          if date
            extra_metadata[:dated] = date
            break
          else
            puts "!!! Invalid date (use ISO8601 format, or leave empty)"
          end
        end
      end

      def prompt_for_author(defaults)
        author = prompt('Author', defaults.author)
        extra_metadata[:author] = author unless author.empty?
      end

      def prompt_for_notes(defaults)
        notes = prompt('Notes', defaults.notes)
        extra_metadata[:notes] = notes unless notes.empty?
      end

      def prompt_for_tags(defaults)
        raw_tags = prompt("Tags", defaults.tags) do |tags|
          tags.map{ '#' + _1 }.join(' ')
        end

        tags = raw_tags.strip.split.map { _1.delete_prefix('#') }.reject(&:empty?)
        if tags.any?
          extra_metadata[:tags] = tags
        end
      end

      def prompt(title, default_value)
        default_text =
          if default_value.nil?
            ''
          elsif block_given?
            " (#{yield(default_value)})"
          else
            " (#{default_value})"
          end

        print "  #{title}#{default_text}: "
        result = gets
        if result
          result.chomp
        else
          fail "No value provided for #{title}"
        end
      end

      def puts(...)
        @stdout.puts(...)
      end

      def print(...)
        @stdout.print(...)
      end

      def gets(...)
        @stdin.gets(...)
      end
  end
end
