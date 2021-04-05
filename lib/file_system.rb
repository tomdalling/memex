module FileSystem
  module Interface
    def read(path); end
    def write(path, content); end
    def exists?(path); end
    def copy(src_path, dest_path); end
    def children_of(directory_path); end
    def delete(path); end
    # from Nodoor::FileSystem
    def each_file_under(directory, &block); end
    def open(path, &block); end
    def exist?(path); end
  end

  self_implements Interface
  extend self

  def read(path)
    File.read(path)
  end

  def write(path, content)
    File.write(path, content)
  end

  def exists?(path)
    File.exist?(path)
  end

  def copy(src_path, dest_path)
    FileUtils.cp(src_path, dest_path)
  end

  def children_of(directory_path)
    Pathname(directory_path).children
  end

  def delete(path)
    File.unlink(path)
  end

  def each_file_under(directory_path, &block)
    Nodoor::FileSystem.each_file_under(directory_path, &block)
  end

  def open(path, &block)
    File.open(path.to_s, &block)
  end

  def exist?(path)
    exists?(path)
  end
end
