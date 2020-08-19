RootContext.context Todoist::ErrorDetails do
  subject = class_under_test.from_json(
    "error_code" => 15,
    "error" => "Invalid temporary id",
  )

  test "has an error code" do
    assert_eq(subject.error_code, 15)
  end

  test "has an error message" do
    assert_eq(subject.error, "Invalid temporary id")
  end
end
