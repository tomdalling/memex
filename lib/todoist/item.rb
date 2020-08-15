module Todoist
  class Item
    include JsonSemantics
    json_semantics do
      id Types::Id
      parent_id Types::Nilable[Types::Id]
      project_id Types::Id
      content Types::String
      due Types::Nilable[Due]
      label_ids Types::SetOf[Types::Id], json_key: 'labels'
      priority Types::Priority
      child_order Types::Integer
      checked? Types::Bool, json_key: 'checked'
      deleted? Types::Bool, json_key: 'is_deleted'
      collapsed? Types::Bool, json_key: 'collapsed'
      added_at Types::Time, json_key: 'date_added'
      completed_at Types::Nilable[Types::Time], json_key: 'date_completed'
    end

    def self.[](attrs)
      defaults = {
        parent_id: nil,
        content: '',
        due: nil,
        label_ids: [],
        priority: 4,
        child_order: 0,
        checked?: false,
        deleted?: false,
        collapsed?: false,
        added_at: Time.now,
        completed_at: nil,
      }
      new(defaults.merge(attrs))
    end

    def scheduled?
      !!due
    end

    def subitem?
      !!parent_id
    end

    def recurring?
      due&.recurring?
    end

    def due?
      due && (due.today? || due.overdue?)
    end

    def labelled?(label_id)
      label_ids.include?(label_id)
    end
  end
end
