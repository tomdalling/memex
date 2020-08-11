module Todoist::TimeCoercer
  def self.call(value)
    if value.is_a?(String)
      Time.iso8601(value)
    else
      value
    end
  end
end
