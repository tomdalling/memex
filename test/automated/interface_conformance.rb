RootContext.context "DuckCheck Interfaces" do
  test "all have conforming implementations" do
    DuckCheck.check!
    assert(true)
  end
end
