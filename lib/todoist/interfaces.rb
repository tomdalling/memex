module Todoist

  module IType
    def validator
      returns #===(other)
    end

    def json_coercer
      returns #call(value)
    end
  end

  module IDecorator
    def initialize(model, decorated_everything)
      returns void
    end
  end

  module IEndpoint
    def request(...)
      returns Client::Request
    end

    def map_response(response)
      param response, Faraday::Response
      returns Object
    end
  end

  module ICommand
    def type
      returns Symbol
    end
  end

end
