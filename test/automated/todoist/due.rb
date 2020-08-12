context Todoist::Due do
  context "with fixed date" do
    subject = class_under_test['2000-01-02T03:04:05Z']

    test "detects the type" do
      assert_eq(subject.type, :fixed)
      assert_predicate(subject, :fixed?)
    end

    test "parses the date" do
      assert_eq(subject.date, Date.new(2000, 1, 2))
    end

    test "parses the time in UTC timezone" do
      assert_eq(subject.time, Time.utc(2000, 1, 2, 3, 4, 5))
    end
  end

  context "with floating date" do
    subject = class_under_test['2000-01-02T03:04:05']

    test "detects the type" do
      assert_eq(subject.type, :floating)
      assert_predicate(subject, :floating?)
    end

    test "parses the date" do
      assert_eq(subject.date, Date.new(2000, 1, 2))
    end

    test "parses the time in local timezone" do
      assert_eq(subject.time, Time.local(2000, 1, 2, 3, 4, 5))
    end
  end

  context "with full_day date" do
    subject = class_under_test['2000-01-02']

    test "detects the type" do
      assert_eq(subject.type, :full_day)
      assert_predicate(subject, :full_day?)
    end

    test "parses the date" do
      assert_eq(subject.date, Date.new(2000, 1, 2))
    end

    test "has a nil time" do
      assert_eq(subject.time, nil)
    end
  end
end
