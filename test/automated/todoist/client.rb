context Todoist::Client do
  subject = context_arg.new(Config[:todoist_api_token])

  def vcr_test(name, &block)
    cassette = "#{context_arg}/#{name}"
    context do
      detail 'Cassette: ' + cassette
      VCR.use_cassette(cassette) do
        test(name, &block)
      end
    end
  end

  vcr_test "lists all items" do
    assert_all(subject.items) { _1.is_a?(Todoist::Item) }
  end
end
