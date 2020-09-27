module Reference
  class CLI::Open < Dry::CLI::Command
    desc "Opens a reference doc"
    argument :doc_id, required: true

    def call(doc_id:, **)
      doc = Doc.new(doc_id)
      if doc.exists?
        Memex.sh('open', doc.path.to_path)
      else
        $stderr.puts("Document not found")
        abort
      end
    end
  end
end
