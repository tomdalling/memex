module Todoist
  class Decorators::Project < SimpleDelegator
    implements IDecorator

    def initialize(item, everything)
      super(item)
      @everything = everything
    end

    def item(query)
      @everything.item(query, project_id: id)
    end
  end
end
