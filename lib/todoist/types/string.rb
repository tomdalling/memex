module Todoist
  module Types::String
    implements IType

    extend self

    def validator
      ::String
    end

    def coercer
      :itself.to_proc
    end
  end
end
