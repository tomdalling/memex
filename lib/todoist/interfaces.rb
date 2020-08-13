module Todoist

  module IType
    def validator
      returns #===(other)
    end

    def coercer
      returns #call(value)
    end
  end

  module IDecorator
    def initialize(model, decorated_everything)
      returns void
    end
  end

end
