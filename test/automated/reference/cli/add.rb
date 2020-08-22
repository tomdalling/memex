RootContext.context Reference::CLI::Add do

  fs = FileSystemFake.new(
    "/in/greetings.txt" => "hello",
    "/ref/2020-12-25_001.png" => "filename taken",
  )
  stdout = StringIO.new
  subject = class_under_test.new(
    file_system: fs,
    config: Struct.new(:reference_dir).new(Pathname('/ref')),
    now: ->() { Time.iso8601('2020-12-25T09:00:00+10:00') },
    fulltext_extractor: ->(path:, file_system:) { 'full text here' },
    stdout: stdout,
    interactive_metadata: ->(path:, noninteractive_metadata:) do
      noninteractive_metadata.with(notes: 'my notes')
    end
  )

  subject.call(files: ["/in/greetings.txt"], tags: %w(a b c))

  test "does not affect existing ref files" do
    assert_eq(fs.read('/ref/2020-12-25_001.png'), 'filename taken')
  end

  test "generates a unique filename based on the time and existing files" do
    assert_eq(fs.read('/ref/2020-12-25_002.txt'), 'hello')
  end

  test "extracts full text into a sidecar file" do
    assert_eq(fs.read('/ref/2020-12-25_002.fulltext.txt'), 'full text here')
  end

  test "writes metadata into a separate file" do
    assert(fs.exists?('/ref/2020-12-25_002.metadata.yml'))
  end

  test "outputs stuff" do
    assert_eq(stdout.string, <<~END_OUTPUT)
      >>> Ingested "/ref/2020-12-25_002.txt" from "/in/greetings.txt"
    END_OUTPUT
  end

  context 'metadata' do
    metadata = Reference::Metadata.from_yaml(
      fs.read('/ref/2020-12-25_002.metadata.yml'),
    )

    test "includes `added_at`" do
      assert_eq(metadata.added_at, Time.iso8601('2020-12-25T09:00:00+10:00'))
    end

    test "includes `original_filename`" do
      assert_eq(metadata.original_filename, 'greetings.txt')
    end

    test "includes `tags`" do
      assert_eq(metadata.tags, %w(a b c))
    end

    test "includes the result of interactive metadata" do
      assert_eq(metadata.notes, "my notes")
    end
  end
end
