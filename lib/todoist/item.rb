module Todoist
  class Item
    include JsonConstructable[
      :checked => :checked?,
      :is_deleted => :deleted?,
      :collapsed => :collapsed?,
      :labels => :label_ids,
      :date_added => :added_at,
      :date_completed => :completed_at,
    ]

    value_semantics do
      id  Integer
      parent_id  Either(Integer, nil)
      content  String
      due  Either(Due, nil), coerce: Due.method(:coerce)
      label_ids  ArrayOf(Integer)
      priority  Either(1,2,3,4)
      checked?  Bool(), coerce: BoolCoercer
      deleted?  Bool(), coerce: BoolCoercer
      collapsed?  Bool(), coerce: BoolCoercer
      added_at  Time, coerce: TimeCoercer
      completed_at  Either(Time, nil), coerce: TimeCoercer
    end

    def scheduled?
      !!due
    end
  end
end
