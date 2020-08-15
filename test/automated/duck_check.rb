context DuckCheck do
  subject = DuckCheck::Registry.new
  # this is a hack only needed for test isolation
  SubjectMixin = subject.class_methods_mixin

  module IDuck
    def quack!
      returns String
    end

    def eat(food)
      param food, Array[SliceOfBread]
      returns void
    end

    def waddle(*locations, speed:, &callback)
      param locations, Array[Location]
      param speed, Float

      yields_to callback do |location|
        param location Location
        returns void
      end

      returns void
    end
  end

  context 'with conforming class' do
    class Mallard
      extend SubjectMixin
      implements IDuck
      def quack!; end
      def eat(food); end
      def waddle(*location, speed:, &block); end
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
      def eat(breakfast, lunch, dinner); end
      def waddle(*locations, speed:); end
    end

    test "raises an error when checking conformance" do
      assert_raises(DuckCheck::NonconformanceError) do
        subject.check!(Whale)
      end
    end

    test "detects unimplemented methods" do
      assert_infringement("`Whale` does not implement `IDuck#quack!`")
    end

    test "detects when implementor does not handle interface params" do
      assert_infringement(<<~END_MSG.strip.gsub(/\s+/, ' '))
        `Whale#waddle(*locations, speed:)`
        does not handle parameters `(&callback)` of
        `IDuck#waddle(*locations, speed:, &callback)`
      END_MSG
    end

    test "detects when implementer has extraneous required params" do
      assert_infringement(<<~END_MSG.strip.gsub(/\s+/, ' '))
        `Whale#eat(breakfast, lunch, dinner)`
        has required parameters `(lunch, dinner)` that are not required in
        `IDuck#eat(food)`
      END_MSG
    end
  end

  context 'with a module' do
    module Duckable
      extend SubjectMixin
      implements IDuck
    end

    test 'still detects infringements' do
      refute_empty(subject.infringements(implementor: Duckable))
    end
  end

  context 'mixin' do
    module IOne; end
    module ITwo; end
    module IThree; end

    class Threeterface
      extend SubjectMixin
    end

    test "records instance-level declarations" do
      Threeterface.implements(IOne, ITwo, IThree)
      assert_predicate(Threeterface, :implements?, IOne)
      assert_predicate(Threeterface, :implements?, ITwo)
      assert_predicate(Threeterface, :implements?, IThree)
    end

    test "records class-level declarations" do
      Threeterface.class_implements(IOne, ITwo)
      assert_predicate(Threeterface, :class_implements?, IOne)
      assert_predicate(Threeterface, :class_implements?, ITwo)

      refute_predicate(Threeterface, :class_implements?, IThree)
    end
  end

  context 'ignoring args' do
    module IIgnored
      def nocheck(...); end
    end

    class ManyParams
      extend SubjectMixin
      implements IIgnored
      def nocheck(a, b=1, *c, d:, e:1, **f, &g); end
    end

    test "does not check compatibility when interface params are (...)" do
      refute_raises DuckCheck::NonconformanceError do
        subject.check!(ManyParams)
      end
    end
  end

  def assert_infringement(message, caller_location: nil)
    caller_location ||= caller_locations.first

    registry = SubjectMixin::DUCK_CHECK_REGISTRY
    all_messages = registry.infringements.map(&:to_s)
    assert_includes(all_messages, message, caller_location: caller_location)
  end
end
