module Reference
  class CLI::Remove < Dry::CLI::Command
    desc "Removes documents from the reference section of the memex"
    argument :ids, type: :array, required: true, desc: "The identifiers of documents to remove"

    def initialize(file_system: FileSystem, config: Config.instance, stdout: $stdout)
      @file_system = file_system
      @config = config
      @stdout = stdout
    end

    def call(ids: [])
      if ids.empty?
        abort("Didn't specify any document ids")
      else
        ids.each { remove(_1) }
        puts "Done"
      end
    end

    private

      def puts(...)
        @stdout.puts(...)
      end

      def remove(document_id)
        puts "== #{document_id}"
        paths_associated_with(document_id).each do |path|
          puts "  Deleting #{path}"
          @file_system.delete(path)
        end
      end

      def paths_associated_with(document_id)
        @file_system.children_of(@config.reference_dir)
          .select { _1.basename.to_s.start_with?(document_id + '.') }
      end
  end
end
