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
