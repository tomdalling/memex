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

      def implements(interface, implementor)
        records << Record.new(interface: interface, implementor: implementor)
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
          def implements(interface)
            singleton_class::DUCK_CHECK_REGISTRY.implements(interface, self)
          end

          def self.included(base)
            registry = self::DUCK_CHECK_REGISTRY
            base.const_set("DuckCheck_MonkeyPatch_#{registry.object_id}", self)
          end
        end.tap do |m|
          m.const_set(:DUCK_CHECK_REGISTRY, self)
        end
      end

      private

        def infringements_for_record(record)
          record.interface.instance_methods.flat_map do |method_name|
            infringement_types_for_method(method_name, record: record)
              .map { |type| Infringement.for(type, method_name, record) }
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
        public_send(type, method_name, record)
      end

      def to_s
        message
      end

      private

        def self.not_implemented(method_name, record)
          f_impl = format_implementor(record.implementor)
          f_method = format_method(record.interface.instance_method(method_name))
          new(
            message: "#{f_impl} does not implement #{f_method}",
            record: record,
          )
        end

        def self.wrong_arity(method_name, record)
          f_impl = format_method(record.implementor.instance_method(method_name))
          f_iface = format_method(record.interface.instance_method(method_name))
          new(
            message: "#{f_impl} does not match arity of #{f_iface}",
            record: record,
          )
        end

        def self.no_block_param(method_name, record)
          f_impl = format_method(record.implementor.instance_method(method_name))
          f_iface = format_method(record.interface.instance_method(method_name))
          new(
            message: "#{f_impl} does not take a block like #{f_iface}",
            record: record,
          )
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
        lines = ["DuckCheck found the following infringements:"] +
          infringements.map(&:to_s)

        new(lines.join("\n  - ") + "\n")
      end
    end
end
