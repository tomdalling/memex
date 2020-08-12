module Todoist::Types::Integer
  extend self

  def validator
    ::Integer
  end

  def coercer
    :itself.to_proc
  end
end
