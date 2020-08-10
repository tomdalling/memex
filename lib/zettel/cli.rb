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

    args = [
      { 'XDG_CONFIG_DIRS' => Memex::VIM_RUNTIME_DIR.to_path },
      ENV.fetch("EDITOR"),
      '--cmd', 'let g:loaded_prosession = 1', # prosession interferes with startup commands
      *relative_args,
    ]
    kwargs = { chdir: chdir.to_path }

    puts 'system(' + (args.map(&:inspect) + kwargs.map{ "#{_1}: #{_2.inspect}"}).join(', ') + ')'
    system(*args, **kwargs)
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
      when "print-path" then puts doc.path.relative_path_from(Pathname.pwd)
      else raise "Unknown --then option"
      end
    end

    private
      def template(title: "Title goes here")
        clean_title = title.gsub(Zettel::Doc::HASHTAG_REGEX, "").strip.gsub(/\s+/, ' ')
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
    option :backlinking_to, desc: "Only list zettels that link to this identifier"

    example [
      '',
      "--hashtags '#a && !#b'",
      "--backlinking-to x0r",
    ]

    attr_reader :zettel_repo, :relative_to

    def initialize(zettel_repo: Zettel::Doc, relative_to: Dir.pwd)
      @zettel_repo = zettel_repo
      @relative_to = relative_to
    end

    def call(hashtags: nil, backlinking_to: nil)
      filter = multi_filter(
        hashtag_filter(hashtags),
        backlink_filter(backlinking_to),
      )

      @zettel_repo.each do |doc|
        if filter.(doc)
          path = doc.path.relative_path_from(@relative_to).to_path
          puts [path, doc.id, doc.title].join("\t")
        end
        doc.purge! # save some memory
      end
    end

    private
      NULL_PREDICATE = ->(doc) { true }

      def multi_filter(*filters)
        ->(doc) do
          filters.all? { _1.(doc) }
        end
      end

      def hashtag_filter(query_string)
        if query_string
          q = Zettel::HashtagQuery.parse(query_string)
          ->(doc) { q.match?(doc.hashtags) }
        else
          NULL_PREDICATE
        end
      end

      def backlink_filter(zettel_id)
        if zettel_id
          path = @zettel_repo[zettel_id].path
          ->(doc) { doc.links_to?(path) }
        else
          NULL_PREDICATE
        end
      end
  end

  extend Dry::CLI::Registry
  register "new", New
  register "open", Open
  register "list", List
end
