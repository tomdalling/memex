module CustomAssertions
  def assert_eq(actual, expected, caller_location: nil)
    caller_location ||= caller_locations.first

    if nil == actual && nil == expected
      detail "Must be non-nil, but actual and expected values were both `nil`. Use `assert_nil` if this is intended."
    else
      detail "Expected: #{expected.inspect}"
      detail "  Actual: #{actual.inspect}"
    end

    assert(
      actual == expected && expected != nil,
      caller_location: caller_location,
    )
  end

  def assert_nil(actual, caller_location: nil)
    assert(
      nil == actual,
      caller_location: caller_location || caller_locations.first,
    )
  end

  def assert_includes(haystack, *needles, caller_location: nil)
    assfute_includes(haystack, needles,
      assert_method: :assert,
      detail_prefix: "should include",
      caller_location: caller_location || caller_locations.first,
    )
  end

  def refute_includes(haystack, *needles, caller_location: nil)
    assfute_includes(haystack, needles,
      assert_method: :refute,
      detail_prefix: "should EXclude",
      caller_location: caller_location || caller_locations.first,
    )
  end

  def assfute_includes(
    haystack,
    needles,
    caller_location:,
    detail_prefix:,
    assert_method:
  )
    context do
      detail "Collection: #{haystack.inspect}"
      needles.each do |n|
        test do
          detail "#{detail_prefix}: #{n.inspect}"
          send(assert_method, haystack.include?(n), caller_location: caller_location)
        end
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

  def capture_stdout
    old_stdout = $stdout
    $stdout = StringIO.new
    yield
    return $stdout.string
  ensure
    $stdout = old_stdout
  end

  def with_cassette(name, &block)
    cassette = "#{context_arg}/#{name}"
    detail 'Cassette: ' + cassette
    VCR.use_cassette(cassette, &block)
  end
end
