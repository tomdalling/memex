module Todoist

  module IType
    def validator
      returns #===(other)
    end

    def coercer
      returns #call(value)
    end
  end

end
