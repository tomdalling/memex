module Todoist
  module Types::Bool
    implements IType

    extend self

    def validator
      ValueSemantics::Bool
    end

    def coercer
      ->(value) do
        case value
        when 1 then true
        when 0 then false
        else value
        end
      end
    end
  end
end
