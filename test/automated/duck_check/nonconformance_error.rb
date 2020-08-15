context DuckCheck::NonconformanceError do
  subject = class_under_test.for_infringements([
    "wigwam",
    "wozzle",
  ])
  test "has a nicely formatted message" do
    assert_eq(subject.message, <<~END_MESSAGE)


      ====[ DuckCheck::NonconformanceError ]================================

      Incompatibilities were detected between some implementations and their
      declared interfaces:

        - wigwam

        - wozzle

      ======================================================================


    END_MESSAGE
  end
end
