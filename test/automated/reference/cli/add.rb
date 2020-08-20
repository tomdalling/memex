RootContext.context Reference::CLI::Add do

  fs = FileSystemFake.new("/in/greetings.txt" => "hello")
  subject = class_under_test.new(
    file_system: fs,
    config: Struct.new(:reference_dir).new(Pathname('/ref')),
    random: RandomFake.new,
    now: ->() { Time.iso8601('2020-12-25T09:00:00+10:00') },
    fulltext_extractor: ->(path:, file_system:) { 'full text here' },
  )

  subject.call(files: ["/in/greetings.txt"], tags: %w(a b c))

  test "copies the file into the correct folder, using a randomly generated filename" do
    assert_eq(fs.read('/ref/aaaa.txt'), 'hello')
  end

  test "extracts full text into a sidecar file" do
    assert_eq(fs.read('/ref/aaaa.fulltext.txt'), 'full text here')
  end

  test "writes metadata into a separate file" do
    assert(fs.exists?('/ref/aaaa.metadata.yml'))
  end

  context 'metadata' do
    metadata = YAML.safe_load(
      fs.read('/ref/aaaa.metadata.yml'),
      symbolize_names: true,
    )

    test "includes `added_at`" do
      assert_eq(metadata[:added_at], '2020-12-25T09:00:00+10:00')
    end

    test "includes `original_filename`" do
      assert_eq(metadata[:original_filename], 'greetings.txt')
    end

    test "includes `tags`" do
      assert_eq(metadata[:tags], %w(a b c))
    end
  end
end
