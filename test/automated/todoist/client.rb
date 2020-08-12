context Todoist::Client do
  subject = class_under_test.new(Config[:todoist_api_token])

  test "loads everything" do
    everything = with_cassette("everything") { subject.everything }
    assert_is_a(everything, Todoist::Everything)
    refute_empty(everything.items)
    refute_empty(everything.labels)
  end
end
