#
# Represents a zettel on disk. Lazily loads and parses the zettel content.
#
class Zettel::Doc
  attr_reader :path

  IDENTIFIER_CHARS = ('a'..'z').to_a + ('0'..'9').to_a
  EXTENSION = ".md"
  SEARCH_DIR = Config.instance.zettel_dir

  def self.[](id)
    path = (SEARCH_DIR / id).sub_ext(EXTENSION)
    new(path)
  end

  def self.each
    SEARCH_DIR.each_child do |path|
      yield new(path) if path.extname == EXTENSION
    end
  end

  def self.new_unused
    100.times do
      id = IDENTIFIER_CHARS.sample(3).join
      doc = self[id]
      return doc unless doc.exists?
    end

    fail "Couldn't find a free zettel identifier within a sensible time"
  end

  def initialize(path, content: nil)
    @path = Pathname(path)
    @content = content
  end

  def id
    path.basename(".*").to_s
  end

  def exists?
    path.exist?
  end

  def create!(content)
    path.write(content, mode: 'wx') # never overwrites
    purge!
    @content = content.dup

    self
  end

  def delete!
    path.delete
    self
  end

  def title
    @title ||= begin
      partial_content =
        if @content
          @content # use entire content
        else
          path.open(mode: 'r') { _1.gets } # only read first line
        end

      partial_content[/\A#\s+(.*)$/, 1]
    end
  end

  def content
    @content ||= begin
      purge!
      File.read(path)
    end
  end

  HASHTAG_REGEX_IGNORING_PRECEDING = /#([a-z0-9_]+)/
  HASHTAG_REGEX = Regexp.new('\s' + HASHTAG_REGEX_IGNORING_PRECEDING.to_s)

  def hashtags
    @hashtags ||= Set.new(
      content.scan(HASHTAG_REGEX).flatten
    )
  end

  LINK_REGEX = %r{
    \[ # open square bracket
      (?<text>[^\]]+) # link text
    \] # close square backet
    \( # open round bracket
      (?<href>[^)]+) # link href
    \) # close round bracket
  }x

  def links
    @links ||= content.to_enum(:scan, LINK_REGEX).to_h do
      [
        Regexp.last_match(:text),
        Addressable::URI.parse(Regexp.last_match(:href))
      ]
    end
  end

  def links_to?(other_path)
    other_pathname = Pathname(other_path)

    links.any? do |_, href|
      href.relative? && other_pathname == path.parent / href.path
    end
  end

  def purge!
    @content&.clear # frees memory
    @content = nil
    @title = nil
    @hashtags = nil
    @links = nil

    self
  end

  def inspect
    "\#<#{self.class} #{path}>"
  end
end
