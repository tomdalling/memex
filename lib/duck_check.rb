module DuckCheck
  extend self

  extend Forwardable
  def_delegators :default_registry,
    *%i(implements check! infringements)

  def default_registry
    @default_registry ||= Registry.new
  end

  def monkey_patch!
    Module.include(default_registry.class_methods_mixin)
  end

  private

    class Record
      value_semantics do
        implementor Module
        interface Module
      end
    end

    class NonconformanceError < StandardError
      def self.for_infringements(infringements)
        new(<<~END_MESSAGE)
          some implementations do not conform to their declared interfaces

          DuckCheck found the following interface infringements:
          #{infringements.map { "  - #{_1}" }.join("\n")}
        END_MESSAGE
      end
    end
end

require_relative 'duck_check/registry'
