module Todoist
  class Project
    include JsonSemantics
    json_semantics do
      id Types::Id
      name Types::String
    end
  end
end
