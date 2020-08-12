module CustomAssertions
  def assert_eq(actual, expected, caller_location: nil)
    caller_location ||= caller_locations.first

    detail "Expected: #{expected.inspect}"
    detail "  Actual: #{actual.inspect}"
    assert(actual == expected, caller_location: caller_location)
  end

  def assert_includes(haystack, *needles, caller_location: nil)
    caller_location ||= caller_locations.first

    detail "Haystack: #{haystack.inspect}"
    needles.each do |n|
      test do
        detail "  Needle: #{n.inspect}"
        assert(haystack.include?(n), caller_location: caller_location)
      end
    end
  end

  def refute_empty(collection, caller_location: nil)
    caller_location ||= caller_locations.first

    detail "Collection: #{collection.inspect}"
    refute(collection.empty?, caller_location: caller_location)
  end

  def assert_all(collection, caller_location: nil, &predicate)
    caller_location ||= caller_locations.first

    assert_empty_or_all(collection, caller_location: caller_location, &predicate)
    # refute empty AFTER assert_empty_or_all, so that it does the `detail`s
    refute(collection.empty?, caller_location: caller_location)
  end

  def assert_empty_or_all(collection, caller_location: nil, &predicate)
    caller_location ||= caller_locations.first

    detail "Collection: #{collection.inspect}"
    collection.each do |element|
      test do
        detail "   Element: #{element.inspect}"
        assert(predicate.(element))
      end
    end
  end

  def assert_predicate(obj, method_name, *args, caller_location: nil, assert_truthy: true, **kwargs, &block)
    caller_location ||= caller_locations.first

    negation = assert_truthy ? ' ' : ' not '
    formatted_args =
      args.map(&:inspect) +
      kwargs.map { "#{_1.inspect}=>#{_2.inspect}" }
    formatted_block = block ? " do ..." : ""
    formatted_call = "#{obj.inspect}.#{method_name}(#{formatted_args.join(', ')})#{formatted_block}"

    detail "Predicate:#{negation}#{formatted_call}"

    result = obj.public_send(method_name, *args, **kwargs, &block)
    if assert_truthy
      assert(result)
    else
      refute(result)
    end
  end

  def refute_predicate(*args, **kwargs, &block)
    assert_predicate(*args, **kwargs.merge(assert_truthy: false), &block)
  end

  def assert_is_a(obj, type)
    detail "Expected type: #{type}"
    detail "  Actual type: #{obj.class} (#{obj.inspect})"
    assert(obj.is_a?(type))
  end

  def assert_matches(str, regex)
    detail "Pattern: #{regex}"
    detail "  Value: #{str.inspect}"
    assert(regex.match?(str))
  end

  def with_tempfile(content:, filename: nil)
    filename ||= SecureRandom.hex(8) + '.tmp'
    path = TEST_TMP_DIR / filename

    file = File.new(path, "w")
    file.write(content)
    file.close

    yield path.to_path
  ensure
    file.close if file
    path.delete if path&.exist?
  end

  def with_cassette(name, &block)
    cassette = "#{context_arg}/#{name}"
    detail 'Cassette: ' + cassette
    VCR.use_cassette(cassette, &block)
  end
end
