RootContext.context Reference::CLI::Add do
  fs = FileSystemFake.new(
    "/in/greetings.txt" => "hello",
    "/ref/2020-12-25_001.png" => "filename taken",
  )
  config = OpenStruct.new(
    reference_dir: Pathname('/ref'),
    reference_templates: []
  )
  stdout = StringIO.new
  subject = class_under_test.new(
    file_system: fs,
    config: config,
    now: ->() { Time.iso8601('2222-02-22T09:00:00+10:00') },
    stdout: stdout,
    interactive_metadata: ->(path:, noninteractive_metadata:) do
      noninteractive_metadata.with(
        dated: Date.new(2020, 12, 25),
        delete_after_ingestion?: true,
      )
    end
  )

  subject.call(
    files: ["/in/greetings.txt"],
    tags: %w(a b c),
    author: 'Einstein',
    notes: 'my notes',
    title: 'The Theory of Relativity 2, Electric Boogaloo',
  )

  test "generates a unique filename based on the `dated` metadata" do
    assert_eq(fs.read('/ref/2020-12-25_002.txt'), 'hello')
  end

  test "does not affect existing ref files" do
    assert_eq(fs.read('/ref/2020-12-25_001.png'), 'filename taken')
  end

  test "writes metadata into a separate file" do
    assert(fs.exists?('/ref/2020-12-25_002.txt.nodoor_metadata.yml'))
  end

  test "outputs stuff" do
    assert_eq(stdout.string, <<~END_OUTPUT)
      >>> Ingested "/ref/2020-12-25_002.txt" from "/in/greetings.txt"
      --- Deleted "/in/greetings.txt"
    END_OUTPUT
  end

  test 'deletes the original file (if told to)' do
    refute(fs.exists?('/in/greetings.txt'))
  end

  context 'metadata' do
    metadata = Reference::Metadata.from_yaml(
      fs.read('/ref/2020-12-25_002.txt.nodoor_metadata.yml'),
    )

    test "includes `added_at`" do
      assert_eq(metadata.added_at, Time.iso8601('2222-02-22T09:00:00+10:00'))
    end

    test "includes `original_filename`" do
      assert_eq(metadata.original_filename, 'greetings.txt')
    end

    test "includes `tags`" do
      assert_eq(metadata.tags, %w(a b c))
    end

    test "includes `author`" do
      assert_eq(metadata.author, 'Einstein')
    end

    test "includes `notes`" do
      assert_eq(metadata.notes, 'my notes')
    end

    test 'includes `title`' do
      assert_eq(metadata.title, 'The Theory of Relativity 2, Electric Boogaloo')
    end

    test "includes the result of interactive metadata" do
      assert_eq(metadata.dated, Date.new(2020, 12, 25))
    end
  end

  context 'using template' do
    config.reference_templates << Reference::Template.new(
      name: 'hamlet',
      tags: %w(t1 t2),
      notes: 'notes',
      author: 'Shakespeare',
    )

    subject = class_under_test.new(
      file_system: fs,
      stdout: StringIO.new,
      config: config,
    )

    fs.reset!
    subject.call(
      files: ["/in/greetings.txt"],
      template: 'hamlet',
      interactive: false,
    )

    metadata = Reference::Metadata.from_yaml(
      fs.read(fs.find(/yml$/))
    )

    test 'uses the template values for metadata' do
      assert_eq(metadata.tags, %w(t1 t2))
      assert_eq(metadata.notes, 'notes')
      assert_eq(metadata.author, 'Shakespeare')
    end
  end
end
