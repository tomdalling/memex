module Todoist
  class Types::SetOf
    implements IType

    def self.[](subtype)
      new(subtype)
    end

    def initialize(subtype)
      @subtype = subtype
    end

    def validator
      ->(value) do
        value.is_a?(Set) &&
          value.all? { @subtype.validator === _1 }
      end
    end

    def json_coercer
      ->(value) do
        if value.is_a?(Enumerable)
          Set.new(
            value.map { @subtype.json_coercer.(_1) }
          )
        else
          value
        end
      end
    end
  end
end
