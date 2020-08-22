class TrioTranscript
  attr_reader :stdin, :stdout, :stderr

  def initialize(stdin: NullInput, stdout: NullOutput, stderr: NullOutput)
    @transcript = ""
    @stdin = IOSpy.new(coerce_stdin(stdin), on_read: true, callback: method(:intercept))
    @stdout = IOSpy.new(stdout, on_write: true, callback: method(:intercept))
    @stderr = IOSpy.new(stderr, on_write: true, callback: method(:intercept))
  end

  def to_s
    @transcript
  end

  def trio
    { stdin: stdin, stdout: stdout, stderr: stderr }
  end

  def duo
    { stdin: stdin, stdout: stdout }
  end

  module NullInput
    extend IO::Like

    private

      def self.unbuffered_read(length)
        raise EOFError, "#{self} never has any input"
      end
  end

  module NullOutput
    extend IO::Like

    private

      def self.unbuffered_write(string)
        string.bytesize
      end
  end

  class IOSpy
    include IO::Like

    def initialize(io, callback:, on_read: false, on_write: false)
      @io = io
      @callback = callback
      @on_read = on_read
      @on_write = on_write

      super()
      self.sync = true
      self.fill_size = 0
      self.flush_size = 0
    end

    private
      def unbuffered_read(length)
        @io.sysread(length).tap do |string|
          @callback.(string) if @on_read
        end
      end

      def unbuffered_seek(offset, whence = IO::SEEK_SET)
        @io.sysseek(offset, whence)
      end

      def unbuffered_write(string)
        @callback.(string) if @on_write
        @io.syswrite(string)
      end
  end

  private

    def coerce_stdin(stdin)
      if stdin.is_a?(String)
        StringIO.new(stdin)
      elsif stdin.respond_to?(:read)
        stdin
      else
        fail("Can't use as stdin: #{stdin.inspect}")
      end
    end

    def intercept(string)
      @transcript << string
    end
end
