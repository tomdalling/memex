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
            infringements_for_method(method_name, record: record)
          end
        end

        def infringements_for_method(method_name, record:)
          infringement_types_for_method(method_name, record: record).map do |type|
            Infringement.for(type, method_name, record)
          end
        end

        def infringement_types_for_method(method_name, record:)
          unless record.implementor.instance_methods.include?(method_name)
            return [:not_implemented]
          end

          infringement_types = []

          iface_method = record.interface.instance_method(method_name)
          impl_method = record.implementor.instance_method(method_name)
          if iface_method.arity != impl_method.arity
            infringement_types << :wrong_arity
          end

          if takes_block?(iface_method) && !takes_block?(impl_method)
            infringement_types << :no_block_param
          end

          infringement_types
        end

        def takes_block?(method)
          method.parameters.any? { _1.first == :block }
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
        record Record
        message String
      end

      def self.for(type, method_name, record)
        new(
          message: public_send("#{type}_message", method_name, record),
          record: record,
        )
      end

      def to_s
        message
      end

      private

        def self.not_implemented_message(method_name, record)
          f_impl = format_implementor(record.implementor)
          f_method = format_method(record.interface.instance_method(method_name))
          "#{f_impl} does not implement #{f_method}"
        end

        def self.wrong_arity_message(method_name, record)
          f_impl = format_method(record.implementor.instance_method(method_name))
          f_iface = format_method(record.interface.instance_method(method_name))
          "#{f_impl} does not match arity of #{f_iface}"
        end

        def self.no_block_param_message(method_name, record)
          f_impl = format_method(record.implementor.instance_method(method_name))
          f_iface = format_method(record.interface.instance_method(method_name))
          "#{f_impl} does not take a block like #{f_iface}"
        end

        def self.format_implementor(implementor)
          "`#{implementor}`"
        end

        def self.format_method(method)
          "`#{method.owner}\##{method.name}#{format_param_list(method.parameters)}`"
        end

        def self.format_param_list(params)
          if params.empty?
            ''
          else
            params
              .map { format_param(*_1) }
              .join(', ')
              .then { '(' + _1 + ')' }
          end
        end

        def self.format_param(type, name)
          case type
          when :req then name.to_s
          when :rest then "*#{name}"
          when :block then "&#{name}"
          when :keyreq then "#{name}:"
          else "<#{type}>#{name}"
          end
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
