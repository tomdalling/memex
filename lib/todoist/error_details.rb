module Todoist
  class ErrorDetails
    include JsonSemantics
    json_semantics do
      error_code Types::Integer
      error Types::String
    end

    def ok?
      false
    end
  end
end
