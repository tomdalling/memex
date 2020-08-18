module Todoist
  class Types::Nilable
    implements IType

    def self.[](subtype)
      new(subtype)
    end

    def initialize(subtype)
      @subtype = subtype
    end

    def validator
      ->(value) do
        value == nil || @subtype.validator === value
      end
    end

    def json_coercer
      ->(value) do
        if value != nil
          @subtype.json_coercer.(value)
        else
          value
        end
      end
    end
  end
end
