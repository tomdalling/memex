context Todoist::Client do
  subject = class_under_test.new('bf677783696428c88493cdd1ff1ea010092b8e02')
  with_cassette("everything") { subject.fetch! }

  test "loads items" do
    refute_empty(subject.items)
  end

  test "wraps a convenience decorator around items" do
    item = subject.items.find { _1.labels.any? }
    assert_all(item.labels) { _1.name.is_a?(String) }
  end

  test "loads labels" do
    refute_empty(subject.labels)
  end

  test "loads everything" do
    assert(subject.everything)
  end

  test "finds labels by name" do
    # TODO: probs don't hardcode this label name
    label = subject.label("At_Home")
    assert(label)
  end

  test "finds labels by id" do
    # TODO: probs don't hardcode this label id
    label = subject.label(id: 2154881693)
    assert(label)
  end

  test "runs commands" do
    create_cmd = Todoist::Commands::CreateItem.new(
      content: "Memex integration test: #{__FILE__}:#{__LINE__}",
      temp_id: UUID.random,
    )
    delete_cmd = Todoist::Commands::DeleteItem.new(
      id: create_cmd.temp_id,
    )

    result =
      with_cassette("create_and_delete") do
        subject.run_commands([create_cmd, delete_cmd])
      end

    assert_predicate(result, :ok?)
  end

  test "handles error responses" do
    assert_raises class_under_test::ResponseError do
      with_cassette("auth_failed") do
        subject.fetch!
      end
    end
  end
end
