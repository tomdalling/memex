module Todoist
  class Client
    def initialize(token)
      @token = token
    end

    def items
      decorate(everything.items)
    end

    def labels
      decorate(everything.labels)
    end

    def label(name_or_attrs)
      decorate(everything.label(name_or_attrs))
    end

    def fetch!
      @everything = run_endpoint(SyncRead)
      nil
    end

    def everything
      fetch! unless @everything
      @everything
    end

    def run_commands(*commands)
      run_endpoint(SyncCommands, commands.flatten)
    end

    private

      def decorate(obj)
        Decorators.decorate(obj, everything)
      end

      def run_endpoint(endpoint, *args, **kwargs, &block)
        request = endpoint.request(*args, **kwargs, &block)
        response = connection.run_request(
          request.http_method,
          request.path,
          request.params.merge(token: @token),
          request.headers,
        )
        endpoint.map_response(response)
      end

      def connection
        @connection ||= Faraday.new(url: 'https://api.todoist.com') do
          _1.request :json
          _1.response :json
          _1.adapter Faraday.default_adapter
        end
      end
  end
end
