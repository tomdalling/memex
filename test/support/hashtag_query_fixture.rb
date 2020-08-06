class HashtagQueryFixture
  include TestBench::Fixture

  value_semantics do
    query_string String
    block Proc
  end

  def self.build(query_string, &block)
    new(query_string: query_string, block: block)
  end

  def call
    context "with syntax: #{query_string}" do
      block.call(self)
    end
  end

  def query
    @query ||= Zettel::HashtagQuery.parse(query_string)
  end

  def assert_matches(*tag_sets)
    tag_sets.each do |ts|
      test do
        detail "should match #{ts.inspect}"
        assert(query.match?(ts))
      end
    end
  end

  def refute_matches(*tag_sets)
    tag_sets.each do |ts|
      test do
        detail "should NOT match #{ts.inspect}"
        refute(query.match?(ts))
      end
    end
  end
end

