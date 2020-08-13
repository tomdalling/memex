require_relative 'item'
require_relative 'label'
require_relative 'project'

module Todoist
  class Everything
    include JsonSemantics
    json_semantics do
      items Types::ArrayOf[Item]
      labels Types::ArrayOf[Label]
      projects Types::ArrayOf[Project]
    end
  end
end
