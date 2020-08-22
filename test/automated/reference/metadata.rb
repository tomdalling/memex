RootContext.context Reference::Metadata do
  attrs = {
    original_filename: 'original.pdf',
    added_at: Time.iso8601('2222-02-22T22:22:22Z'),
    tags: %w(t1 t2 t3),
    notes: 'some notes',
    dated: Date.new(1111, 11, 11),
    author: 'Henry V',
  }
  yaml = {
    "original_filename" => 'original.pdf',
    "added_at" => '2222-02-22T22:22:22Z',
    "tags" => %w(t1 t2 t3),
    "notes" => 'some notes',
    "dated" => '1111-11-11',
    "author" => 'Henry V',
  }

  test "serialises everything to YAML" do
    assert_eq(
      class_under_test.new(attrs).to_yaml,
      YAML.dump(yaml),
    )
  end

  test "loads everything from YAML" do
    assert_eq(
      class_under_test.from_yaml(YAML.dump(yaml)),
      class_under_test.new(attrs),
    )
  end
end
