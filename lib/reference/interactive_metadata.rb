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
      prompt_for_dated
      prompt_for_author
      prompt_for_notes
      prompt_for_tags(noninteractive_metadata.tags)
    end

    private

      def prompt_for_dated
        loop do
          print "  Dated: "

          answer = gets.strip
          break if answer.empty?

          date = parse_date(answer)
          if date
            extra_metadata[:dated] = date
            break
          else
            puts "Invalid date (use ISO8601 format, or leave empty)"
          end
        end
      end

      def parse_date(text)
        Date.iso8601(text)
      rescue Date::Error
        nil
      end

      def prompt_for_author
        print "  Author: "
        author = gets.strip
        extra_metadata[:author] = author unless author.empty?
      end

      def prompt_for_notes
        print "  Notes: "
        notes = gets.strip
        extra_metadata[:notes] = notes unless notes.empty?
      end

      def prompt_for_tags(default_tags)
        default_text =
          if default_tags&.any?
            ' (' + default_tags.map{ '#' + _1 }.join(' ') + ')'
          else
            ''
          end

        print "  Tags#{default_text}: "

        tags = gets.strip.split.map { _1.delete_prefix('#') }.reject(&:empty?)
        if tags.any?
          extra_metadata[:tags] = tags
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
