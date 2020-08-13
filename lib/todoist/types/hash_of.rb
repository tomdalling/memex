module Todoist
  class Types::HashOf
    implements IType

    def self.[](key_to_value)
      if key_to_value.size != 1
        raise ArgumentError, "One key and one value please"
      end

      new(key_to_value.keys.first, key_to_value.values.first)
    end

    def initialize(key_type, value_type)
      @key_type = key_type
      @value_type = value_type
    end

    def validator
      ->(value) do
        value.is_a?(Hash) &&
          value.keys.all? { @key_type.validator === _1 } &&
          value.values.all? { @value_type.validator === _1 }
      end
    end

    def coercer
      ->(value) do
        if value.is_a?(Hash)
          value.to_h do
            [@key_type.coercer.(_1), @value_type.coercer.(_2)]
          end
        else
          value
        end
      end
    end
  end
end
