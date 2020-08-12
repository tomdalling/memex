require_relative 'item'
require_relative 'label'

module Todoist
  class Everything
    include JsonSemantics
    json_semantics do
      items Types::ArrayOf[Item]
      labels Types::ArrayOf[Label]
    end
  end
end
