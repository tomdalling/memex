#!/usr/bin/env ruby

require_relative '_bootstrap'

module Zettle
  extend self

  IDENTIFIER_CHARS = ('a'..'z').to_a + ('0'..'9').to_a
  ZETTLE_DIR = MEMEX_ROOT/"zettle"
  HASHTAG_REGEX = /#[a-z0-9_-]+/
  ZETTLE_VIM_PATH = MEMEX_ROOT/"lib/zettle.vim"

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
    ZETTLE_DIR.join(identifier).sub_ext(".md")
  end

  def each_id
    ZETTLE_DIR.each_child do |path|
      yield path.basename(".*") if path.extname == ".md"
    end
  end

  def run_editor(*args)
    args.map! { _1.is_a?(Pathname) ? _1.to_path : _1 }
    system(
      ENV.fetch("EDITOR"),
      '-S', ZETTLE_VIM_PATH.to_path,
      *args,
      chdir: ZETTLE_DIR.to_path,
    )
  end
end


module Zettle::CLI
  extend Dry::CLI::Registry

  class New < Dry::CLI::Command
    desc "Creates a new zettle file and opens it for editing"
    option :then, default: "edit", values: %w(edit print-path), desc: "What to do after creating the new zettle"
    example '"Pathname is good #ruby"'
    example 'Pathname is good "#ruby"'

    def call(args: [], **options)
      id = Zettle.new_identifier
      title = args.empty? ? "Title goes here" : args.join(' ')
      template = Zettle.write_template(id, title: title)

      case options.fetch(:then)
      when "edit" then run_editor(id, template)
      when "print-path" then puts Zettle.path(id).to_path
      else raise "Unknown --then option"
      end
    end

    private

      def run_editor(id, template)
        Zettle.run_editor('-c', 'normal G$', '--', Zettle.path(id))

        if Zettle.content(id).strip == template.strip
          puts "Deleting new zettle due to being empty"
          Zettle.delete(id)
        end
      end
  end

  class Open < Dry::CLI::Command
    desc "Starts vim with :ZettleOpen"

    def call
      Zettle.run_editor('-c', 'ZettleOpen!')
    end
  end

  class List < Dry::CLI::Command
    desc "Lists zettles in tabular format"

    def call(**options)
      Zettle.each_id do |identifier|
        title = Zettle.title(identifier)
        path = Zettle.path(identifier).relative_path_from(Dir.pwd)
        puts [path, identifier, title].join("\t")
      end
    end
  end

  register "new", New
  register "open", Open
  register "list", List
end


ARGV << "open" if ARGV.empty?
Dry::CLI.new(Zettle::CLI).call
