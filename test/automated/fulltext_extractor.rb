RootContext.context FulltextExtractor do
  subject = module_under_test

  test "extracts from .txt files" do
    assert_eq(
      subject.(
        path: "abc.txt",
        file_system: FileSystemFake.new("abc.txt" => "abcdefg"),
      ),
      "abcdefg"
    )
  end

  test "extracts .pdf files" do
    extracted = subject.(path: TEST_DATA_DIR / 'extract_me.pdf')
    assert_eq(
      extracted.downcase.gsub(/[^a-z]+/, ' ').strip,
      'i am the very model of a modern major general',
    )
  end
end
