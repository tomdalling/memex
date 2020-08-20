class FileSystemFake
  attr_reader :files

  def initialize(files = {})
    @files = files.to_h { [to_path(_1), _2] }
  end

  ######################################################################
  implements FileSystem::Interface

  def write(path, content)
    @files[to_path(path)] = content.to_s
  end

  def read(path)
    @files.fetch(to_path(path)) do
      fail "File does not exist at: #{path}"
    end
  end

  def exists?(path)
    @files.key?(to_path(path))
  end

  def copy(src, dest)
    @files[to_path(dest)] = @files[to_path(src)]
  end

  ######################################################################
  private

    def to_path(obj)
      case obj
      when String then obj
      when Pathname then obj.to_path
      else fail "Not a path: #{obj.inspect}"
      end
    end
end
