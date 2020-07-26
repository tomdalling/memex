#!/usr/bin/env ruby

require_relative '_bootstrap'

module Zettel
  extend self

  IDENTIFIER_CHARS = ('a'..'z').to_a + ('0'..'9').to_a
  HASHTAG_REGEX = /#[a-z0-9_-]+/

  def new_identifier
    loop do
      identifier = IDENTIFIER_CHARS.sample(3).join
      return identifier unless exists?(identifier)
    end
  end

  def new_path
    path(new_identifier)
  end

  def write_template(identifier, title: "Title goes here")
    hashtags = ["#unprocessed"] + title.scan(HASHTAG_REGEX)
    title = title.gsub(HASHTAG_REGEX, "").strip.gsub(/\s+/, " ")
    template = <<~END_TEMPLATE
      # #{title}
      Tags: #{hashtags.join(' ')}

      Description goes here.

      ## References

    END_TEMPLATE

    path(identifier).write(template, mode: 'wx') # never overwrites

    template
  end

  def exists?(identifier)
    path(identifier).exist?
  end

  def title(identifier)
    path(identifier).open(mode: 'r') do |f|
      return f.gets.strip.delete_prefix("# ").strip
    end
  end

  def content(identifier)
    path(identifier).read
  end

  def delete(identifier)
    path(identifier).delete
  end

  def path(identifier)
    Memex::ZETTEL_DIR.join(identifier).sub_ext(".md")
  end

  def each_id
    Memex::ZETTEL_DIR.each_child do |path|
      yield path.basename(".*") if path.extname == ".md"
    end
  end

  def run_editor(*args)
    system(
      { 'XDG_CONFIG_DIRS' => Memex::VIM_RUNTIME_DIR.to_path },
      ENV.fetch("EDITOR"),
      *args.map{ _1.is_a?(Pathname) ? _1.to_path : _1 },
      chdir: Memex::ZETTEL_DIR.to_path,
    )
  end
end


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
        Zettel.run_editor('-c', 'normal G$', '--', Zettel.path(id))

        if Zettel.content(id).strip == template.strip
          puts "Deleting new zettel due to being empty"
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


ARGV << "open" if ARGV.empty?
Dry::CLI.new(Zettel::CLI).call
