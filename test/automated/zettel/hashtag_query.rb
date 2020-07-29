require_relative '../../init'

TestBench.context Zettel::HashtagQuery do

  class HashtagQueryFixture
    include TestBench::Fixture

    value_attrs do
      query String
      asserted_matches ArrayOf(ArrayOf(String))
      refuted_matches ArrayOf(ArrayOf(String)), default: []
    end

    def call
      subject = Zettel::HashtagQuery.parse(query)

      asserted_matches.each do |expected|
        test "'#{query}' matches #{expected.inspect}" do
          assert(subject.match?(expected))
        end
      end

      refuted_matches.each do |unexpected|
        test "'#{query}' does not match #{unexpected.inspect}" do
          refute(subject.match?(unexpected))
        end
      end
    end
  end

  test "hashtags" do
    fixture(HashtagQueryFixture,
      query: '#a',
      asserted_matches: [%w(a), %w(a b)],
      refuted_matches: [%w(), %w(b)],
    )
  end

  test "logical NOT" do
    fixture(HashtagQueryFixture,
      query: 'NOT #a',
      asserted_matches: [%w(), %w(b)],
      refuted_matches: [%w(a)],
    )
  end

  test "logical AND" do
    fixture(HashtagQueryFixture,
      query: '#a AND #b',
      asserted_matches: [%w(a b), %w(a b c)],
      refuted_matches: [%w(a), %w(b)],
    )
  end

  test "logical OR" do
    fixture(HashtagQueryFixture,
      query: '#a OR #b',
      asserted_matches: [%w(a), %w(b), %w(a b)],
      refuted_matches: [%w(), %w(c)],
    )
  end

  test "NOT has higher precedence than AND or OR" do
    fixture(HashtagQueryFixture,
      query: 'NOT #a AND NOT #b OR NOT #c',
      asserted_matches: [%w(a), %w(b), %w(c)],
      refuted_matches: [%w(a c), %w(b c)],
    )
  end

  test "left-to-right precendence" do
    fixture(HashtagQueryFixture,
      query: '#a AND #b OR #c', # ((#a AND #b) OR #c)
      asserted_matches: [%w(a b), %w(c)],
    )
  end

  test "explicit precedence with parens" do
    fixture(HashtagQueryFixture,
      query: '#a AND (#b OR #c)',
      asserted_matches: [%w(a b), %w(a c)],
      refuted_matches: [%w(c)],
    )
  end

  test "complex nesting" do
    fixture(HashtagQueryFixture,
      query: '#a AND (NOT (#b OR #c) AND () #d)',
      asserted_matches: [%w(a d), %w(a x d)],
      refuted_matches: [%w(a b d), %w(a c d), %w(a)],
    )
  end

  test "alternate AND syntax" do
    fixture(HashtagQueryFixture,
      query: '#a AND #b and #c & #d && #e',
      asserted_matches: [%w(a b c d e)],
      refuted_matches: [%w(a b c d)],
    )
  end

  test "alternate OR syntax" do
    fixture(HashtagQueryFixture,
      query: '#a OR #b or #c | #d || #e',
      asserted_matches: [%w(a), %w(b), %w(c), %w(d), %w(e)],
      refuted_matches: [%w(z)],
    )
  end

  test "alternate NOT syntax" do
    fixture(HashtagQueryFixture,
      query: 'NOT #a AND not #b AND !#c',
      asserted_matches: [%w(z)],
      refuted_matches: [%w(a), %w(b), %w(c)],
    )
  end
end
