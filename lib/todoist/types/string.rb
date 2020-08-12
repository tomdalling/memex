module Todoist::Types::String
  extend self

  def validator
    ::String
  end

  def coercer
    :itself.to_proc
  end
end
