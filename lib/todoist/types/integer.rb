module Todoist
  module Types::Integer
    implements IType

    extend self

    def validator
      ::Integer
    end

    def json_coercer
      :itself.to_proc
    end
  end
end
