class ZettelRepoFake

  ##############################################################################
  # Repo interface
  ##############################################################################

  def each(...)
    @zettels.each(...)
  end

  def [](zettel_id)
    existing = @zettels.find { _1.id == zettel_id }
    if existing
      existing
    else
      append(path: "#{zettel_id}.md")
    end
  end

  ##############################################################################
  # Methods for use in testing
  ##############################################################################

  def initialize
    @zettels = []
  end

  def append(path: "abc.md", title: "Title", tags: '#fake', body: 'Body text')
    @zettels << Zettel::Doc.new(path, content: <<~END_ZETTEL)
      # #{title}
      Tags: #{tags}

      #{body}
    END_ZETTEL
    @zettels.last
  end
end
