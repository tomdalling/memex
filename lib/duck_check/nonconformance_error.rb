module DuckCheck
  class NonconformanceError < StandardError
    LINE_WIDTH = 70

    def self.for_infringements(infringements)
      new("\n\n" + <<~END_MESSAGE + "\n\n")
        #{"====[ #{self} ]".ljust(LINE_WIDTH, '=')}

        Incompatibilities were detected between some implementations and their
        declared interfaces:

        #{infringements.map { list_item(_1) }.join("\n\n")}

        #{'='*LINE_WIDTH}
      END_MESSAGE
    end

    private

      ITEM_PREFIX = "  - "

      def self.list_item(infringement)
        lines = []
        this_line = ""

        this_line << ITEM_PREFIX.chomp(' ')
        split_into_words(infringement.to_s).each do |word|
          proposed_line = this_line + ' ' + word
          if proposed_line.length < LINE_WIDTH
            this_line = proposed_line
          else
            lines << this_line
            this_line = ' '*ITEM_PREFIX.length + word
          end
        end

        lines << this_line unless this_line.empty?
        lines.join("\n")
      end

      def self.split_into_words(text)
        backticks_seen = 0
        output = []

        text.split(/\s+/).each do |word|
          if backticks_seen.even?
            # not inside backticks right now
            output << word
          else
            # inside backticks. don't split these
            output.last << ' ' + word
          end
          backticks_seen += word.count('`')
        end

        output
      end
  end
end
