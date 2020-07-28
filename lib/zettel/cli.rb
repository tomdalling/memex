module Zettel::CLI
  extend Dry::CLI::Registry

  class New < Dry::CLI::Command
    desc "Creates a new zettel file and opens it for editing"
    option :then, default: "edit", values: %w(edit print-path), desc: "What to do after creating the new zettel"
    example '"Pathname is good #ruby"'
    example 'Pathname is good "#ruby"'

    def call(args: [], **options)
      id = Zettel.new_identifier
      title = args.empty? ? "Title goes here" : args.join(' ')
      template = Zettel.write_template(id, title: title)

      case options.fetch(:then)
      when "edit" then run_editor(id, template)
      when "print-path" then puts Zettel.path(id).to_path
      else raise "Unknown --then option"
      end
    end

    private

      def run_editor(id, template)
        success = Zettel.run_editor('-c', 'normal G$', '--', Zettel.path(id))

        if !success
          puts "Editor not exit successfully. Deleting: #{Zettel.path(id)}"
          Zettel.delete(id)
        elsif Zettel.content(id).strip == template.strip
          puts "Zettel was unedited. Deleting: #{Zettel.path(id)}"
          Zettel.delete(id)
        end
      end
  end

  class Open < Dry::CLI::Command
    desc "Starts vim inside the zettelkasten"
    argument :zettel_id, desc: "The identifier of the zettel to open"

    def call(zettel_id: nil, **)
      if zettel_id
        Zettel.run_editor("#{zettel_id}.md")
      else
        Zettel.run_editor('-c', 'ZettelOpen!')
      end
    end
  end

  class List < Dry::CLI::Command
    desc "Lists zettels in tabular format"

    def call(**options)
      Zettel.each_id do |identifier|
        title = Zettel.title(identifier)
        path = Zettel.path(identifier).relative_path_from(Dir.pwd)
        puts [path, identifier, title].join("\t")
      end
    end
  end

  register "new", New
  register "open", Open
  register "list", List
end
