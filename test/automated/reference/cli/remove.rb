RootContext.context Reference::CLI::Remove do
  fs = FileSystemFake.new(
    "/ref/thing.pdf" => "hello",
    "/ref/thing.fulltext.txt" => "hello",
    "/ref/thing.metadata.yml" => "hello",
  )

  subject = class_under_test.new(
    file_system: fs,
    config: Struct.new(:reference_dir).new(Pathname('/ref')),
    stdout: StringIO.new,
  )

  subject.call(ids: ['thing'])

  test "deletes the document" do
    refute(fs.exists?("/ref/thing.pdf"))
  end

  test "deletes the extracted fulltext" do
    refute(fs.exists?("/ref/thing.fulltext.txt"))
  end

  test "deletes the metadata" do
    refute(fs.exists?("/ref/thing.metadata.yml"))
  end
end
