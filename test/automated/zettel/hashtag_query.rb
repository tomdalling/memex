require_relative '../../test_init'

context Zettel::HashtagQuery do
  test "matches the presence of a hashtag" do
    fixture(HashtagQueryFixture, '#a') do
      _1.assert_matches(%w(a), %w(a b))
      _1.refute_matches(%w(), %w(b))
    end
  end

  test "provides logical NOT" do
    ['NOT #a', 'not #a', '!#a'].each do |query|
      fixture(HashtagQueryFixture, query) do
        _1.assert_matches(%w(), %w(b))
        _1.refute_matches(%w(a))
      end
    end
  end

  test "provides logical AND" do
    %w(AND and & &&).each do |operator|
      fixture(HashtagQueryFixture, "#a #{operator} #b") do
        _1.assert_matches(%w(a b), %w(a b c))
        _1.refute_matches(%w(a), %w(b))
      end
    end
  end

  test "provides logical OR" do
    %w(OR or | ||).each do |operator|
      fixture(HashtagQueryFixture, "#a #{operator} #b") do
        _1.assert_matches(%w(a), %w(b), %w(a b))
        _1.refute_matches(%w(), %w(c))
      end
    end
  end

  test "gives NOT a higher precedence than AND and OR" do
    fixture(HashtagQueryFixture, '!#a AND !#b AND !#c') do
      _1.assert_matches(%w(), %w(d))
      _1.refute_matches(%w(a), %w(b), %w(c))
    end

    fixture(HashtagQueryFixture, '!#a OR !#b OR !#c') do
      _1.assert_matches(%w(), %w(a), %w(b), %w(c))
      _1.refute_matches(%w(a b c))
    end
  end

  test "is left-associative" do
    fixture(HashtagQueryFixture, '#a AND #b OR #c') do
      _1.assert_matches(%w(a b), %w(c))
    end
  end

  test "allows brackets for explicit precedence" do
    fixture(HashtagQueryFixture, '#a AND (#b OR #c)') do
      _1.assert_matches(%w(a b), %w(a c))
      _1.refute_matches(%w(c))
    end
  end

  test "allows arbitrary nesting" do
    fixture(HashtagQueryFixture, '(#a) AND (NOT (#b OR (#c)) AND () #d)') do
      _1.assert_matches(%w(a d), %w(a x d))
      _1.refute_matches(%w(a b d), %w(a c d), %w(a))
    end
  end
end
