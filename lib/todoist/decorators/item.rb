module Todoist
  class Decorators::Item < SimpleDelegator
    implements IDecorator

    def initialize(item, everything)
      super(item)
      @everything = everything
    end

    def label?(label)
      label_id =
        case label
        when String then @everything.label(name: label_name).id
        when Integer then label
        else label.id
        end

      label_ids.include?(label_id)
    end

    def labels
      label_ids.map do
        @everything.label(id: _1)
      end
    end

    def children
      @everything.items.select { _1.parent_id == id }
    end
  end
end
