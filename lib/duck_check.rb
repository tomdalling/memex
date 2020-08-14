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

    class Registry
      attr_reader :records

      def initialize
        @records = []
      end

      def implements(implementor, *interfaces)
        records.concat(
          interfaces.map do
            Record.new(interface: _1, implementor: implementor)
          end
        )
      end

      def implements?(implementor, interface)
        records.any? do
          _1.interface.equal?(interface) && _1.implementor.equal?(implementor)
        end
      end

      def check!(implementor = nil)
        infringements = infringements(implementor: implementor)
        if infringements.any?
          raise NonconformanceError.for_infringements(infringements)
        end
      end

      def infringements(implementor: nil)
        records_to_check =
          if implementor
            records.select { _1.implementor.equal?(implementor) }
          else
            records
          end

        records_to_check.flat_map { infringements_for_record(_1) }
      end

      def class_methods_mixin
        Module.new do
          def duck_check_registry
            singleton_class::DUCK_CHECK_REGISTRY
          end

          def implements(*interfaces)
            duck_check_registry.implements(self, *interfaces)
          end

          def implements?(interface)
            duck_check_registry.implements?(self, interface)
          end

          def class_implements(*interfaces)
            duck_check_registry.implements(singleton_class, *interfaces)
          end

          def class_implements?(interface)
            duck_check_registry.implements?(singleton_class, interface)
          end

          def self.included(base)
            name = "DuckCheck_MonkeyPatch_#{base.duck_check_registry.object_id}"
            base.const_set(name, self)
          end
        end.tap do |m|
          m.const_set(:DUCK_CHECK_REGISTRY, self)
        end
      end

      private

        def infringements_for_record(record)
          record.interface.instance_methods.flat_map do |method_name|
            Array(infringements_for_method(method_name, record: record))
          end
        end

        def infringements_for_method(method_name, record:)
          unless record.implementor.instance_methods.include?(method_name)
            return Infringement.not_implemented(method_name, record: record)
          end

          iface = ParamPipe.for_method(record.interface.instance_method(method_name))
          impl = ParamPipe.for_method(record.implementor.instance_method(method_name))
          compat = impl.compatibility_as_substitute_for(iface)

          compat.error_messages.map do |msg|
            Infringement.formatted(
              message: msg,
              method_name: method_name,
              record: record,
            )
          end
        end

    end

    class Record
      value_semantics do
        implementor Module
        interface Module
      end
    end

    class Infringement
      value_semantics do
        message String
        record Record
      end

      def self.not_implemented(method_name, record:)
        formatted(
          message: "does not implement",
          method_name: method_name,
          record: record,
          include_impl_method: false,
        )
      end

      def self.formatted(message:, method_name:, record:, include_impl_method: true)
        iface = format_method(record.interface.instance_method(method_name))
        impl =
          if include_impl_method
            format_method(record.implementor.instance_method(method_name))
          else
            format_implementor(record.implementor)
          end

        new(
          message: "#{impl} #{message} #{iface}",
          record: record,
        )
      end

      def to_s
        message
      end

      private

        def self.format_implementor(implementor)
          "`#{implementor}`"
        end

        def self.format_method(method)
          owner = method.owner.name || "<anon>"
          param_list =
            if method.arity == 0
              ''
            else
              ParamPipe.for_method(method).to_ruby
            end

          "`#{owner}\##{method.name}#{param_list}`"
        end

        # def self.format_param_list(params)
        # end
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
