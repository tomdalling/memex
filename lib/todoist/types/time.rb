module Todoist
  module Types::Time
    implements IType
    extend self

    def validator
      ::Time
    end

    def json_coercer
      ->(value) do
        if value.is_a?(String) && Date._iso8601(value).any?
          Time.iso8601(value)
        else
          value
        end
      end
    end
  end
end
