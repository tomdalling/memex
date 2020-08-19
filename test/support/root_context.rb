# The default TestBench::Fixture used when calling the bare `context` method in
# the global scope.
class RootContext
  include TestBench::Fixture

  def self.context(*args, **kwargs, &block)
    TestBench.context(*args, **kwargs) do
      fixture(RootContext, args.first, block).run_deferred!
    end
  end

  # equivalent of `described_class` from RSpec
  attr_reader :context_arg

  def initialize(context_arg, block)
    @context_arg = context_arg
    @block = block
    @running = false
    @calls = []
  end

  def call
    instance_eval(&@block)
  end

  def class_under_test
    if context_arg.is_a?(Class)
      context_arg
    else
      fail("Context was not a class: #{context_arg.inspect}")
    end
  end

  # defer the tests/contexts (shallow, not recursive)
  # this allows tests to use methods that are defined later in the file
  %w(test context comment detail fixture).each do |method_name|
    eval <<~END_METHOD
      def #{method_name}(*args, **kwargs, &block)
        if @running
          super
        else
          @calls << [:#{method_name}, args, kwargs, block]
        end
      end
    END_METHOD
  end

  # runs the deferred tests/contexts
  def run_deferred!
    @running = true
    @calls.each do |(method_name, args, kwargs, block)|
      send(method_name, *args, **kwargs, &block)
    end
  end
end

RootContext.const_set(:GLOBAL_SCOPE_BINDING, binding)

