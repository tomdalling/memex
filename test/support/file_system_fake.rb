class FileSystemFake
  attr_reader :files

  def initialize(files = {})
    @files = files.to_h { [to_path(_1), _2] }
    @original_files = @files.dup
  end

  def find(regex)
    @files.keys.find { regex === _1 }
  end

  def reset!
    @files = @original_files.dup
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
    !!@files[to_path(path)]
  end

  def copy(src, dest)
    @files[to_path(dest)] = @files[to_path(src)]
  end

  def children_of(directory_path)
    @files
      .keys
      .select { exists?(_1) }
      .map { Pathname(_1) }
      .select { _1.parent == directory_path }
  end

  def delete(path)
    @files.delete(to_path(path)) or fail("Path does not exist: #{path}")
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
