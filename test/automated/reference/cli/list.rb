RootContext.context Reference::CLI::List do
  stdout = StringIO.new
  fs = FileSystemFake.new("/ref/camelot.txt" => <<~TXT)
    ---
    title: King Arthur
    original_filename: round_table.txt
    tags: []
    ...

    Excalibur in the body
  TXT

  subject = class_under_test.new(
    file_system: fs,
    config: Struct.new(:reference_dir).new(Pathname('/ref')),
    stdout: stdout,
  )

  subject.call

  detail "OUTPUT:\n#{stdout.string}"

  test "outputs all documents" do
    assert(stdout.string.strip == "camelot.txt King Arthur (round_table.txt)")
  end
end
