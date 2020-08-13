module Todoist
  class Types::ArrayOf
    implements IType

    def self.[](subtype)
      new(subtype)
    end

    def initialize(subtype)
      @subtype = subtype
    end

    def validator
      ->(value) do
        value.is_a?(Array) &&
          value.all? { @subtype.validator === _1 }
      end
    end

    def coercer
      ->(value) do
        if value.is_a?(Array)
          value.map { @subtype.coercer.(_1) }
        else
          value
        end
      end
    end
  end
end
