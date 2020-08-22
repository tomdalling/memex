module Reference
  class InteractiveMetadata
    attr_reader :extra_metadata

    def initialize(stdin: $stdin, stdout: $stdout)
      @stdin = stdin
      @stdout = stdout
      @extra_metadata = {}
    end

    def call(path:, noninteractive_metadata:)
      extra_metadata.clear
      run(path, noninteractive_metadata)
      noninteractive_metadata.with(extra_metadata)
    end

    def run(path, noninteractive_metadata)
      puts "==[ #{path} ]".ljust(75, '=')
      prompt_for_dated(noninteractive_metadata)
      prompt_for_author(noninteractive_metadata)
      prompt_for_notes(noninteractive_metadata)
      prompt_for_tags(noninteractive_metadata)
    end

    private

      def prompt_for_dated(noninteractive_metadata)
        loop do
          answer = prompt('Dated', noninteractive_metadata.dated) { _1.iso8601 }
          break if answer.empty?

          date = parse_date(answer)
          if date
            extra_metadata[:dated] = date
            break
          else
            puts "!!! Invalid date (use ISO8601 format, or leave empty)"
          end
        end
      end

      def parse_date(text)
        Date.iso8601(text)
      rescue Date::Error
        nil
      end

      def prompt_for_author(noninteractive_metadata)
        author = prompt('Author', noninteractive_metadata.author)
        extra_metadata[:author] = author unless author.empty?
      end

      def prompt_for_notes(noninteractive_metadata)
        notes = prompt('Notes', noninteractive_metadata.notes)
        extra_metadata[:notes] = notes unless notes.empty?
      end

      def prompt_for_tags(noninteractive_metadata)
        raw_tags = prompt("Tags", noninteractive_metadata.tags) do |tags|
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
        gets.chomp
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
