module Todoist::Types::String
  extend self

  def validator
    String
  end

  def coercer
    nil
  end
end
