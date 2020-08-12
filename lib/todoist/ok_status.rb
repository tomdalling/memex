module Todoist
  module OkStatus
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
