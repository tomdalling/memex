module Todoist
  class Label
    include JsonSemantics
    json_semantics do
      id Types::Id
      name Types::String
      color Color
      deleted? Types::Bool, json_key: 'is_deleted'
      favorite? Types::Bool, json_key: 'is_favorite'
    end
  end
end
