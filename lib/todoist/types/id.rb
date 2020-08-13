module Todoist::Types::Id
  extend self

  def validator
    ::Integer
  end

  def coercer
    :itself.to_proc
  end
end