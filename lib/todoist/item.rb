require 'todoist/bool_coercer'
require 'todoist/date_coercer'

module Todoist
  class Item
    value_semantics do
      id Integer
      parent_id Either(Integer, nil)
      content  String
      label_ids  ArrayOf(Integer)
      priority  Either(1,2,3,4)
      checked?  Bool(), coerce: BoolCoercer
      deleted?  Bool(), coerce: BoolCoercer
      collapsed?  Bool(), coerce: BoolCoercer
      date_added  Date, coerce: DateCoercer
      date_completed  Either(Date, nil), coerce: DateCoercer
    end

    JSON_KEY_BY_ATTR = {
      checked?: :checked,
      deleted?: :is_deleted,
      collapsed?: :collapsed,
      label_ids: :labels,
    }

    def self.to_proc
      ->(json) do
        new(
          value_semantics.attributes.map(&:name).to_h do |attr_name|
            key = JSON_KEY_BY_ATTR.fetch(attr_name, attr_name)
            [attr_name, json.fetch(key)]
          end
        )
      end
    end
  end
end
