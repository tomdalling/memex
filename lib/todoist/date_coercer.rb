module Todoist::DateCoercer
  def self.call(value)
    if value.is_a?(String)
      Date.iso8601(value)
    else
      value
    end
  end
end
