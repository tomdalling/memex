module Todoist
  module Types::UUID
    implements IType
    extend self

    def validator
      ::UUID
    end

    def json_coercer
      ->(value) do
        if value.is_a?(String) && UUID.valid_format?(value)
          ::UUID.new(formatted: value)
        else
          value
        end
      end
    end
  end
end
