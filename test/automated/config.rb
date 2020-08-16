context Config do
  test "loads" do
    refute_predicate(Config.todoist.api_token, :empty?)
    refute_predicate(Config.memex.image_path, :nil?)
  end
end
