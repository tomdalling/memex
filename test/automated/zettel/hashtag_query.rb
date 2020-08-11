context Zettel::HashtagQuery do
  def with_subject(query_string)
    context "with syntax: #{query_string}" do
      subject = context_arg.parse(query_string)
      detail "Parsed:\n#{subject.pretty_inspect}"
      yield subject
    end
  end

  test "matches the presence of a hashtag" do
    with_subject('#a') do
      assert_matches(_1, %w(a), %w(a b))
      refute_matches(_1, %w(), %w(b))
    end
  end

  test "provides logical NOT" do
    ['NOT #a', 'not #a', '!#a'].each do |query|
      with_subject(query) do
        assert_matches(_1, %w(), %w(b))
        refute_matches(_1, %w(a))
      end
    end
  end

  test "provides logical AND" do
    %w(AND and & &&).each do |operator|
      with_subject("#a #{operator} #b") do
        assert_matches(_1, %w(a b), %w(a b c))
        refute_matches(_1, %w(a), %w(b))
      end
    end
  end

  test "provides logical OR" do
    %w(OR or | ||).each do |operator|
      with_subject("#a #{operator} #b") do
        assert_matches(_1, %w(a), %w(b), %w(a b))
        refute_matches(_1, %w(), %w(c))
      end
    end
  end

  test "gives NOT a higher precedence than AND and OR" do
    with_subject('!#a AND !#b AND !#c') do
      assert_matches(_1, %w(), %w(d))
      refute_matches(_1, %w(a), %w(b), %w(c))
    end

    with_subject('!#a OR !#b OR !#c') do
      assert_matches(_1, %w(), %w(a), %w(b), %w(c))
      refute_matches(_1, %w(a b c))
    end
  end

  test "is left-associative" do
    with_subject('#a AND #b OR #c') do
      assert_matches(_1, %w(a b), %w(c))
    end
  end

  test "allows brackets for explicit precedence" do
    with_subject('#a AND (#b OR #c)') do
      assert_matches(_1, %w(a b), %w(a c))
      refute_matches(_1, %w(c))
    end
  end

  test "allows arbitrary nesting" do
    with_subject('(#a) AND (NOT (#b OR (#c)) AND () #d)') do
      assert_matches(_1, %w(a d), %w(a x d))
      refute_matches(_1, %w(a b d), %w(a c d), %w(a))
    end
  end

  def assert_matches(query, *tag_sets, caller_location: nil)
    caller_location ||= caller_locations.first

    tag_sets.each do |ts|
      test do
        detail "should match #{ts.inspect}"
        assert(query.match?(ts))
      end
    end
  end

  def refute_matches(query, *tag_sets, caller_location: nil)
    caller_location ||= caller_locations.first

    tag_sets.each do |ts|
      test do
        detail "should NOT match #{ts.inspect}"
        refute(query.match?(ts))
      end
    end
  end
end
