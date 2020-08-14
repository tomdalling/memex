module Todoist
  module OkStatus
    implements IType
    extend self

    def coercer
      ->(value) do
        if value == "ok"
          self
        else
          value
        end
      end
    end

    def validator
      self
    end

    def ok?
      true
    end
  end
end
