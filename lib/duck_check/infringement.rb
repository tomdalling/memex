module DuckCheck
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
            ParamList.for_method(method).to_ruby
          end

        "`#{owner}\##{method.name}#{param_list}`"
      end
  end
end
