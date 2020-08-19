module Todoist
  class Commands::CreateItem
    implements ICommand

    value_semantics do
      content String
      project_id Either(Integer, UUID, nil), default: nil
      parent_id Either(Integer, UUID, nil), default: nil
      child_order Either(Integer, nil), default: nil
      labels Either(ArrayOf(Integer), nil), coerce: true, default: nil
      due Either(Todoist::Due, nil), default: nil # TODO: implement this

      temp_id Either(UUID, nil), default: nil
      uuid UUID, default_generator: UUID.method(:random)
    end

    def self.duplicating(item, **overridden_attrs)
      attrs = {
        content: item.content,
        project_id: item.project_id,
        parent_id: item.parent_id,
        child_order: item.child_order,
        labels: item.label_ids,
        due: item.due,
      }

      new(attrs.merge(overridden_attrs))
    end

    def self.coerce_labels(labels)
      case labels
      when Set then labels.to_a
      else labels
      end
    end

    def type
      :item_add
    end

    def args
      to_h
        .except(:temp_id, :uuid, :due)
        .merge(due: due&.to_command_arg(:date))
        .compact
    end
  end
end
