module DuckCheck
  class Registry
    attr_reader :records

    def initialize
      @records = []
    end

    def implements(implementor, *interfaces, zelf: nil)
      records.concat(
        interfaces.map do
          Record.new(interface: _1, implementor: implementor, zelf: zelf)
        end
      )
    end

    def implements?(implementor, interface, zelf: nil)
      records.include?(
        Record.new(implementor: implementor, interface: interface, zelf: zelf)
      )
    end

    def self_implementors_of(interface)
      records
        .select { _1.zelf && _1.interface.equal?(interface) }
        .map(&:zelf)
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

        def self_implements(*interfaces)
          duck_check_registry.implements(singleton_class, *interfaces, zelf: self)
        end

        def self_implements?(interface)
          duck_check_registry.implements?(singleton_class, interface, zelf: self)
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
        unless record.implementor.instance_methods.include?(method_name)
          return [Infringement.not_implemented(method_name, record: record)]
        end

        iface = ParamList.for_method(record.interface.instance_method(method_name))
        return [] if iface.allow_anything?

        impl = ParamList.for_method(record.implementor.instance_method(method_name))
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
end
