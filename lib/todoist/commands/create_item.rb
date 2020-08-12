require 'uuid'

class Todoist::Commands::CreateItem
  NON_ITEM_ATTRS = %i(temp_id uuid)

  value_semantics do
    content String
    project_id Either(Integer, UUID, nil), default: nil
    parent_id Either(Integer, UUID, nil), default: nil
    label_ids Either(ArrayOf(Integer), nil), coerce: true, default: nil

    temp_id Either(UUID, nil), default: nil
    uuid UUID, default_generator: UUID.method(:random)
  end

  def self.duplicating(item, **overridden_attrs)
    attrs = value_semantics.attributes
      .reject { _1.name.in?(NON_ITEM_ATTRS) }
      .to_h { [_1.name, item.public_send(_1.name)] }
      .merge(overridden_attrs)

    new(attrs)
  end

  def self.coerce_label_ids(label_ids)
    case label_ids
    when Set then label_ids.to_a
    else label_ids
    end
  end

  def type
    :item_add
  end

  def args
    to_h
      .except(*NON_ITEM_ATTRS)
      .compact
  end
end
