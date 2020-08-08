require_relative '../../test_init'

context Zettel::Doc do
  def with_subject(filename: "abc.md", &block)
    with_tempfile(filename: filename, content: typical_zettel_content) do |path|
      yield context_arg.new(path)
    end
  end

  def typical_zettel_content
    <<~END_ZETTEL
      # This is the title
      Tags: #these #are #the_tags #hy-phen

      Hashtags can be #inline. Not tags: abc#def # xyz qqq#

      [A link](abc.md) in the body text and [a multi
      line
      link](xyz.md) too.

      ## References

      > This is a quote in the references section.

      Myself, et al. (2020) _Memex test suite_
      https://github.com/tomdalling/memex/tree/main/test/automated/zettel.rb
    END_ZETTEL
  end

  test "has a path" do
    with_subject do
      assert_predicate(_1.path, :readable?)
    end
  end

  test "extracts the id, without loading the content" do
    with_subject(filename: "x0r.md") do
      _1.path.delete
      assert_eq(_1.id, "x0r")
    end
  end

  test "loads the content, lazily" do
    with_subject do
      File.write(_1.path, "extra!", mode: 'a')
      assert_eq(_1.content, typical_zettel_content + 'extra!')
    end
  end

  context "extracts the title" do
    test "without loading the entire file content" do
      with_subject do
        assert_eq(_1.title, "This is the title")
        assert_eq(_1.instance_variable_get(:@content), nil)
      end
    end

    test "but uses the content if it is already loaded" do
      with_subject do
        _1.content # load content
        _1.path.delete # remove file
        assert_eq(_1.title, "This is the title")
      end
    end
  end

  test "extracts hashtags" do
    assert_eq(
      with_subject(&:hashtags),
      Set.new(%w(these are the_tags inline hy)),
    )
  end

  test "extracts links" do
    assert_eq(with_subject(&:links), {
      "A link" => "abc.md",
      "a multi\nline\nlink" => "xyz.md",
    })
  end

  test "can purge cached attributes" do
    with_subject do
      _1.title; _1.content; _1.hashtags; _1.links # cache values

      File.write(_1.path, "# New content") # overwrite file
      assert_eq(_1.title, "This is the title") # using old, cached value

      return_value = _1.purge!
      assert(return_value.equal?(_1)) # returns self

      # reloaded values
      assert_eq(_1.content, "# New content")
      assert_eq(_1.title, "New content")
      assert_eq(_1.hashtags, Set[])
      assert_eq(_1.links, {})
    end
  end

  test "knows if the file exists" do
    with_subject do
      assert_predicate(_1, :exists?)
      _1.path.delete
      refute_predicate(_1, :exists?)
    end
  end
end
