module Todoist
  class Commands::CompleteItem
    implements ICommand

    value_semantics do
      id Either(Integer, UUID)
      uuid UUID, default_generator: UUID.method(:random)
    end

    def self.[](item)
      case item
      when Integer, UUID
        new(id: item)
      when Todoist::Item, Todoist::Decorators::Item
        new(id: item.id)
      else
        fail("Not an item: #{item.inspect}")
      end
    end

    def type
      :item_close
    end

    def args
      { id: id }
    end

    def temp_id
      nil
    end
  end
end
