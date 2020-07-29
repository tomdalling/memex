class Zettel::Doc
  attr_reader :path

  def initialize(path)
    @path = Pathname(path)
  end

  def id
    @id ||= path.basename(".*").to_s
  end

  def title
    @title ||= content[/\A#\s+(.*)$/, 1]
  end

  def content
    @content ||= File.read(path)
  end

  def hashtags
    @hashtags ||= Set.new(
      content.scan(/\s#[a-z0-9_]+/).map do
        _1.strip.delete_prefix('#')
      end
    )
  end

  LINK_REGEX = %r{
    \[ # open square bracket
      (?<text>[^\]]+) # link text
    \] # close square backet
    \( # open round bracket
      (?<url>[^)]+) # link url
    \) # close round bracket
  }x

  def links
    @links ||= content.to_enum(:scan, LINK_REGEX).to_h do
      m = Regexp.last_match
      [m[:text], m[:url]]
    end
  end

  def purge!
    @content&.clear # frees memory
    @content = nil
    @title = nil
    @hashtags = nil
    @links = nil
  end
end
