context Todoist::Client do
  subject = class_under_test.new(Config[:todoist_api_token])

  def vcr_test(name, &block)
    cassette = "#{class_under_test}/#{name}"
    test(name) do
      detail 'Cassette: ' + cassette
      VCR.use_cassette(cassette, &block)
    end
  end

  vcr_test "lists all items" do
    assert_all(subject.items) { _1.is_a?(Todoist::Item) }
  end
end
