module Todoist::BoolCoercer
  def self.call(value)
    case
    when 1 then true
    when 0 then false
    else value
    end
  end
end
