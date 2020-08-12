context Todoist::Color do
  subject = class_under_test.new(30)

  test "has a number" do
    assert_eq(subject.number, 30)
  end

  test "has a CSS representation" do
    assert_matches(subject.css, /\A#[0-9a-f]{6}\z/)
  end
end
