context DuckCheck do
  subject = DuckCheck::Registry.new
  SubjectMixin = subject.class_methods_mixin

  module IDuck
    def quack!
      returns String
    end

    def eat(food)
      param food, Array[SliceOfBread]
      returns void
    end

    def waddle(*locations, speed:)
      param locations, Array[Location]
      param speed, Float
      yields do |location|
        param location Location
        returns void
      end
    end
  end

  context 'with conforming class' do
    class Mallard
      extend SubjectMixin
      implements IDuck
      def quack!; end
      def eat(food); end
      def waddle(*location, speed:); end
    end

    test "does not include any modules into classes" do
      refute_includes(Mallard.ancestors.inspect, "DuckCheck")
    end

    test "checks that the class conforms to the interface" do
      refute_raises(DuckCheck::NonconformanceError) do
        subject.check!(Mallard)
      end
    end
  end

  context 'with non-conforming class' do
    class Whale
      extend SubjectMixin
      implements IDuck
      def eat; end
    end

    test "raises an error when checking conformance" do
      assert_raises(DuckCheck::NonconformanceError) do
        subject.check!(Whale)
      end
    end

    test "detects unimplemented methods" do
      assert_infringement("`Whale` does not implement `IDuck#quack!`")
    end

    test "detects incorrect arity" do
      assert_infringement("`Whale#eat` does not match arity of `IDuck#eat(food)`")
    end
  end

  def assert_infringement(message, caller_location: nil)
    caller_location ||= caller_locations.first

    registry = SubjectMixin::DUCK_CHECK_REGISTRY
    all_messages = registry.infringements.map(&:to_s)
    assert_includes(all_messages, message, caller_location: caller_location)
  end
end
