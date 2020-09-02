RootContext.context HumanDateParser do
  subject = class_under_test.new(today: Date.new(2222, 2, 22))

  test "returns nil for unparsable dates" do
    assert_nil(subject.('gdq'))
  end

  test "parses today" do
    assert_eq(subject.('tOdAy'), Date.new(2222, 2, 22))
  end

  test "parses yesterday" do
    assert_eq(subject.('yEsTeRdAy'), Date.new(2222, 2, 21))
  end

  test "parses ISO8601 dates" do
    assert_eq(subject.('2001-02-03'), Date.new(2001, 02, 03))
  end

  test "parses solo day numbers" do
    assert_eq(subject.('5'), Date.new(2222, 2, 5))
  end

  test "parses solo day numbers with suffixes" do
    assert_eq(subject.('1st'), Date.new(2222, 2, 1))
    assert_eq(subject.('2nd'), Date.new(2222, 2, 2))
    assert_eq(subject.('3rd'), Date.new(2222, 2, 3))
    assert_eq(subject.('4th'), Date.new(2222, 2, 4))
  end

  test "parses day, short month" do
    assert_eq(subject.('4 JaN'), Date.new(2222, 1, 4))
  end

  test "parses short month, day" do
    assert_eq(subject.('jan 8'), Date.new(2222, 1, 8))
  end

  test "parses day, full month" do
    assert_eq(subject.('5th january'), Date.new(2222, 1, 5))
  end

  test "parses day, month, year" do
    assert_eq(subject.('6 jan 2002'), Date.new(2002, 1, 6))
  end

  test "parses year, month, day" do
    assert_eq(subject.('2003 jan 9'), Date.new(2003, 1, 9))
  end

  test "parses ambiguous day/month/year using Australian conventions" do
    assert_eq(subject.('01/02/2004'), Date.new(2004, 2, 1))
  end
end
