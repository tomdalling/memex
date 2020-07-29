module Zettel::CLI
  def self.run_editor(*args)
    chdir = Memex::ZETTEL_DIR
    relative_args = args.map do
      if _1.is_a?(Pathname)
        _1.relative_path_from(chdir).to_path
      else
        _1 # unchanged
      end
    end

    system(
      { 'XDG_CONFIG_DIRS' => Memex::VIM_RUNTIME_DIR.to_path },
      ENV.fetch("EDITOR"),
      *relative_args,
      chdir: chdir.to_path,
    )
  end

  class New < Dry::CLI::Command
    desc "Creates a new zettel file and opens it for editing"
    option :then, default: "edit", values: %w(edit print-path), desc: "What to do after creating the new zettel"

    example [
      "'Pathname is good #ruby'",
      '--then print-path',
    ]

    def call(args: [], **options)
      title = args.empty? ? "Title goes here" : args.join(' ')
      template = template(title: title)

      doc = Zettel::Doc.new_unused
      doc.create!(template)

      case options.fetch(:then)
      when "edit" then edit(doc, template)
      when "print-path" then puts doc.path.to_path
      else raise "Unknown --then option"
      end
    end

    private
      def template(title: "Title goes here")
        clean_title = title.gsub(Zettel::Doc::HASHTAG_REGEX, "").strip.squeeze
        found_hashtags = title.scan(Zettel::Doc::HASHTAG_REGEX).flatten
        hashtags = (["unprocessed"] + found_hashtags).map{ '#' + _1 }.join(' ')

        <<~END_TEMPLATE
          # #{clean_title}
          Tags: #{hashtags}

          Description goes here.

          ## References


        END_TEMPLATE
      end


      def edit(doc, template)
        success = Zettel::CLI.run_editor('-c', 'normal G$', '--', doc.path)
        doc.purge! # reload changes after editing

        if !success
          puts "Editor not exit successfully. Deleting: #{doc.path}"
          doc.delete!
          abort
        elsif doc.content.strip == template.strip
          puts "Zettel was unedited. Deleting: #{doc.path}"
          doc.delete!
        end
      end
  end

  class Open < Dry::CLI::Command
    desc "Starts vim inside the zettelkasten"
    argument :zettel_id, desc: "The identifier of the zettel to open"

    example [
      '',
      "x0r",
    ]

    def call(zettel_id: nil, **)
      if zettel_id
        doc = Zettel::Doc[zettel_id]
        if doc.exists?
          Zettel::CLI.run_editor(doc.path)
        else
          $stderr.puts "Zettel does not exist: #{doc.path}"
          abort
        end
      else
        Zettel::CLI.run_editor('-c', 'ZettelOpen!')
      end
    end
  end

  class List < Dry::CLI::Command
    desc "Lists zettel in tabular format"
    option :hashtags, desc: "Hashtag query string (e.g. #a AND !#b)"

    example [
      '',
      "--hashtags '#a && !#b'",
    ]

    def call(hashtags: nil)
      query = hashtags && Zettel::HashtagQuery.parse(hashtags)

      Zettel::Doc.each do |doc|
        if query.nil? || query.match?(doc.hashtags)
          path = doc.path.relative_path_from(Dir.pwd).to_path
          puts [path, doc.id, doc.title].join("\t")
        end
        doc.purge! # same some memory
      end
    end
  end

  extend Dry::CLI::Registry
  register "new", New
  register "open", Open
  register "list", List
end
