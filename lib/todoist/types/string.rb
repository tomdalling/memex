module Todoist
  module Types::String
    implements IType
    extend self

    def validator
      ::String
    end

    def json_coercer
      :itself.to_proc
    end
  end
end
