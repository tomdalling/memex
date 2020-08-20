module FulltextExtractor
  def self.call(path:, file_system: FileSystem)
    path = Pathname(path)

    extractor = DuckCheck.self_implementors_of(IExtractor).find do
      _1.handles?(path: path, file_system: file_system)
    end

    if extractor
      extractor.extract(path: path, file_system: file_system)
    else
      '' # no extractor found
    end
  end

  module IExtractor
    def handles?(path:, file_system:); end
    def extract(path:, file_system:); end
  end

  module TextExtractor
    self_implements IExtractor
    extend self

    def handles?(path:, **)
      path.extname.downcase == '.txt'
    end

    def extract(path:, file_system:)
      file_system.read(path)
    end
  end

  module TikaExtractor
    self_implements IExtractor
    extend self

    HANDLED_EXTENSIONS = %w(.pdf)

    def handles?(path:, **)
      path.extname.downcase.in?(HANDLED_EXTENSIONS)
    end

    def extract(path:, file_system:)
      input = file_system.read(path)
      output, error, status = Open3.capture3(
        "tika", "--text", '-',
        stdin_data: input,
      )
      if status.success?
        output
      else
        fail("tika failed: #{error}\n#{output}")
      end
    end
  end
end
