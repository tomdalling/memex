require_relative '../../init'

TestBench.context Zettel::Doc do
  typical_zettel_content = <<~END_ZETTEL
    # This is the title
    Tags: #these #are #the_tags #hy-phen

    Hashtags can be #inline. Not tags: abc#def # xyz qqq#

    [A link](abc.md) in the body text and [a multi
    line link](xyz.md) too.

    ## References

    > This is a quote in the references section.

    Myself, et al. (2020) _Memex test suite_
    https://github.com/tomdalling/memex/tree/main/test/automated/zettel.rb
  END_ZETTEL

  with_subject = ->(filename: "abc.md", &block) do
    path = TEST_TMP_DIR / filename
    file = File.new(path, "w")
    begin
      file.write(typical_zettel_content)
      file.close
      block.call(Zettel::Doc.new(path))
    ensure
      file.close
      path.delete if path.exist?
    end
  end

  test "has a path" do
    with_subject.() do
      assert(_1.path.readable?)
    end
  end

  test "extracts the id, without loading the content" do
    with_subject.(filename: "x0r.md") do
      _1.path.delete
      assert(_1.id == "x0r")
    end
  end

  test "loads the content, lazily" do
    with_subject.() do
      File.write(_1.path, "extra!", mode: 'a')
      assert(_1.content) == typical_zettel_content + 'extra!'
    end
  end

  context "extracts the title" do
    test "without loading the entire file content" do
      with_subject.() do
        assert(_1.title == "This is the title")
        assert(_1.instance_variable_get(:@content) == nil)
      end
    end

    test "but uses the content if it is already loaded" do
      with_subject.() do
        _1.content # load content
        _1.path.delete # remove file
        assert(_1.title == "This is the title")
      end
    end
  end

  test "extracts hashtags" do
    assert(with_subject.(&:hashtags) == Set.new(%w(
      these are the_tags inline hy
    )))
  end

  test "extracts links" do
    assert(with_subject.(&:links) == {
      "A link" => "abc.md",
      "a multi\nline link" => "xyz.md",
    })
  end

  test "can purge cached attributes" do
    with_subject.() do
      _1.title; _1.content; _1.hashtags; _1.links # cache values

      File.write(_1.path, "# New content") # overwrite file
      assert(_1.title == "This is the title") # using old, cached value

      return_value = _1.purge!
      assert(return_value.equal?(_1)) # returns self

      # reloaded values
      assert(_1.content == "# New content")
      assert(_1.title == "New content")
      assert(_1.hashtags == Set[])
      assert(_1.links == {})
    end
  end

  test "knows if the file exists" do
    with_subject.() do
      assert(_1.exists?)
      _1.path.delete
      refute(_1.exists?)
    end
  end
end
