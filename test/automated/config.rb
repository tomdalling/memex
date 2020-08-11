context Config do
  test "loads" do
    refute_predicate(Config[:todoist_api_token], :empty?)
  end
end
