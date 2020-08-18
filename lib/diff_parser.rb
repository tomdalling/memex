class DiffParser
  def self.parse(diff_text)
    new(diff_text).send(:files)
  end

  private

    FILE_START_PREFIX = 'diff --git'
    BINARY_DIFF_PREFIX = 'Binary files'
    SOURCE_LINE_PREFIX = '---'
    DEST_LINE_PREFIX = '+++'
    HUNK_HEADER_PREFIX = '@@'

    def initialize(text)
      @scanner = StringScanner.new(text)
    end

    def files
      [].tap do
        until @scanner.eos?
          _1 << read_file
        end
      end
    end

    def read_file
      src, dst = read_file_start
      headers = read_file_headers
      hunks = []

      if @scanner.match?(BINARY_DIFF_PREFIX)
        read_line
      else
        src = read_source
        dst = read_dest
        hunks = read_hunks
      end

      DiffParser::File.new(
        source: src,
        destination: dst,
        headers: headers,
        hunks: hunks,
      )
    end

    def read_file_start
      @scanner.scan(FILE_START_PREFIX) or fail!("Expected start of file '#{FILE_START_PREFIX}'")
      files = read_line.split
      if files.size == 2
        files
      else
        fail!("Don't know how to handle diff between more than two files: #{files.inspect}")
      end
    end

    def read_file_headers
      [].tap do |lines|
        loop do
          break if @scanner.match?(SOURCE_LINE_PREFIX)
          break if @scanner.match?(BINARY_DIFF_PREFIX)
          break if @scanner.eos?
          lines << read_line
        end
      end
    end

    def read_source
      line = read_line
      unless line.start_with?(SOURCE_LINE_PREFIX)
        fail!("Could not find a source line")
      end

      line.delete_prefix(SOURCE_LINE_PREFIX).strip
    end

    def read_dest
      line = read_line
      unless line.start_with?(DEST_LINE_PREFIX)
        fail!("Could not find a source line")
      end

      line.delete_prefix(DEST_LINE_PREFIX).strip
    end

    def read_hunks
      [].tap do |hunks|
        loop do
          h = read_one_hunk
          if h
            hunks << h
          else
            break
          end
        end
      end
    end

    def read_one_hunk
      @scanner.scan(HUNK_HEADER_PREFIX) or return nil # no more hunks :(
      @scanner.skip(/\s+/)
      src_r = read_hunk_range('-')
      @scanner.skip(/\s+/)
      dst_r = read_hunk_range('+')
      @scanner.skip(/\s+/)
      @scanner.scan(HUNK_HEADER_PREFIX) or fail!("Expected hunk header end '#{HUNK_HEADER_PREFIX}'")
      ctx = read_line.strip
      lines = read_diff_lines

      Hunk.new(
        source_range: src_r,
        destination_range: dst_r,
        context: ctx,
        lines: lines,
      )
    end

    def read_hunk_range(prefix)
      @scanner.scan(prefix) or fail!("Expected source range '#{prefix}'")
      src_start = @scanner.scan(/[0-9]+/) or fail!("Expected source range start")
      src_len =
        if @scanner.match?(',')
          @scanner.scan(',')
          @scanner.scan(/[0-9]+/) or fail!("Expected source range length")
        else
          1 # no second number means that the hunk only affects a single line
        end

      Integer(src_start)...(Integer(src_start) + Integer(src_len))
    end

    def read_diff_lines
      lines = []

      loop do
        l = read_one_diff_line
        if l
          lines << l
        else
          break
        end
      end

      lines
    end

    def read_one_diff_line
      first_char = @scanner.peek(1)
      type =
        case first_char
        when ' ',"\n" then :same
        when '+' then :added
        when '-' then :removed
        else nil
        end

      if type
        Line.new(type: type, text: read_line.delete_prefix(first_char))
      else
        nil
      end
    end

    def read_line
      line = @scanner.scan_until(/\n/)
      if line
        line.chomp("\n")
      else
        fail!("Expected more lines of diff")
      end
    end

    def fail!(msg)
      raise Error, "#{msg} near #{@scanner.peek(40)}"
    end

    class Error < StandardError; end

    class Line
      TYPES = %i(same added removed)

      value_semantics do
        type Either(*TYPES)
        text String
      end

      TYPES.each do |t|
        eval <<~END_RUBY
          def self.#{t}(text)
            new(type: :#{t}, text: text)
          end

          def #{t}?
            type == :#{t}
          end
        END_RUBY
      end
    end

    class Hunk
      value_semantics do
        source_range Range
        destination_range Range
        context String
        lines ArrayOf(Line)
      end
    end

    class File
      value_semantics do
        headers ArrayOf(String)
        source String
        destination String
        hunks ArrayOf(Hunk)
      end
    end
end
