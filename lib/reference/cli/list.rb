module Reference
  class CLI::List < Dry::CLI::Command
    desc "Lists/searches through reference docs"
    option :grep, desc: "String to search for (not a pattern, yet)"

    def call(grep: nil)
      Reference.each do |doc|
        puts output_line(doc) if match?(doc, grep)
      end
    end

    private

      def output_line(doc)
        "#{doc.id} #{doc.metadata.original_filename}"
      end

      def match?(doc, search_str)
        return true unless search_str

        [
          doc.id,
          doc.metadata.author,
          doc.metadata.notes,
          doc.metadata.original_filename,
          doc.metadata.tags,
        ].flatten.compact.any? { |str| str.downcase.include?(search_str.downcase) }
      end
  end
end
