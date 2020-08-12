module Todoist::Types::Priority
  extend self

  VALID_VALUES = Set[1, 2, 3, 4]

  def validator
    ->(value) { VALID_VALUES.include?(value) }
  end

  def coercer
    :itself.to_proc
  end
end
