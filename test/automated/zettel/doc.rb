RootContext.context Zettel::Doc do
  def subject(filename="in_memory_test_zettel.md", content: typical_zettel_content)
    class_under_test.new(filename, content: content)
  end

  test "has a path" do
    assert_eq(subject("xyz.md").path, Pathname("xyz.md"))
  end

  test "extracts the id, without loading the content" do
    assert_eq(subject("x0r.md").id, 'x0r')
  end

  test "loads the content, lazily" do
    with_subject_on_disk do
      _1.path.write("i'm late!")
      assert_eq(_1.content, "i'm late!")
    end
  end

  context "extracts the title" do
    test "without loading the entire file content" do
      with_subject_on_disk(content: "# Turtles\nTags: #turtles") do
        assert_eq(_1.title, "Turtles")
        assert_nil(_1.instance_variable_get(:@content))
      end
    end

    test "uses the content if it is already loaded" do
      with_subject_on_disk(content: "# Turtles\nTags: #turtles") do
        _1.content # load content
        _1.path.delete # remove file
        assert_eq(_1.title, "Turtles")
      end
    end
  end

  test "extracts hashtags" do
    assert_eq(
      subject(content: <<~END_ZETTEL).hashtags,
        # Title
        Tags: #these #are #the_tags #hy-phen

        Hashtags can #be, #inline. Not tags: abc#def # xyz qqq#

        ## References

        whatever
      END_ZETTEL
      Set.new(%w(these are the_tags be inline hy))
    )
  end

  test "extracts links" do
    assert_eq(
      subject(content: <<~END_ZETTEL).links,
        [A link](abc.md) in the body text and [a multi
        line
        link](xyz.md) too.

        A pasted url:
        https://github.com/tomdalling/memex/tree/main/test/automated/zettel.rb
      END_ZETTEL
      {
        "A link" => Addressable::URI.parse("abc.md"),
        "a multi\nline\nlink" => Addressable::URI.parse("xyz.md"),
      }
    )
  end

  test "can purge cached attributes" do
    old_content = <<~END_ZETTEL
      # Old Title

      Tag #old and [link](link.md)
    END_ZETTEL

    with_subject_on_disk(content: old_content) do
      _1.title; _1.content; _1.hashtags; _1.links # cache values

      File.write(_1.path, "# New content") # overwrite file
      assert_eq(_1.title, "Old Title") # using old, cached value

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
    with_subject_on_disk do
      assert_predicate(_1, :exists?)
      _1.path.delete
      refute_predicate(_1, :exists?)
    end
  end

  context "checking links to other paths" do
    doc = subject("some/dir/me.md", content: <<~END_ZETTEL)
      [same dir](sibling.md)
      [subdir](sub/child.md)
      [parent dir](../parent.md)
      [absolute dir](/Users/tom/absolute.md)
      [external](https://example.com/)
    END_ZETTEL

    test "uses relative paths" do
      assert_predicate(doc, :links_to?, "some/dir/sibling.md")
      refute_predicate(doc, :links_to?, "sibling.md")
    end

    test "handles subdirectories" do
      assert_predicate(doc, :links_to?, "some/dir/sub/child.md")
    end

    test "handles parent directories" do
      assert_predicate(doc, :links_to?, "some/parent.md")
    end

    test "handles absolute paths" do
      assert_predicate(doc, :links_to?, "/Users/tom/absolute.md")
    end
  end

  def with_subject_on_disk(filename="test_zettel.md", content: typical_zettel_content, &block)
    with_tempfile(filename: filename, content: content) do |path|
      yield subject(path, content: nil)
    end
  end

  def typical_zettel_content
    <<~END_ZETTEL
      # This is the title
      Tags: #testing #stuff

      Body goes here.

      ## References

      > This is a quote in the references section.

      Myself, et al. (2020) _Memex test suite_
      https://github.com/tomdalling/memex/tree/main/test/automated/zettel.rb
    END_ZETTEL
  end
end
