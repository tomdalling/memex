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
        title = doc.title || '<no title>'
        original_filename = doc.original_filename
          .then { _1 ? "(#{_1})" : '' }
        tags = doc.tags.map{ '#' + _1 }.join(' ')

        "#{doc.id} #{title} #{original_filename} #{tags}"
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