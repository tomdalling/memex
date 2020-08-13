module Todoist
  class Client
    extend Forwardable

    def initialize(token)
      @token = token
    end

    def_delegators :everything,
      *%i(labels label items item projects project)

    def fetch!
      @everything = run_endpoint(SyncRead)
      nil
    end

    def everything
      fetch! unless @everything
      Decorators::Everything.new(@everything)
    end

    def run_commands(*commands)
      run_endpoint(SyncCommands, commands.flatten)
    end

    private
      class ResponseError < StandardError; end

      def run_endpoint(endpoint, *args, **kwargs, &block)
        request = endpoint.request(*args, **kwargs, &block)
        response = connection.run_request(
          request.http_method,
          request.path,
          request.params.merge(token: @token),
          request.headers,
        )
        intercept_response_error(response)
        endpoint.map_response(response)
      end

      def connection
        @connection ||= Faraday.new(url: 'https://api.todoist.com') do
          _1.request :json
          _1.response :json
          _1.adapter Faraday.default_adapter
        end
      end

      def intercept_response_error(response)
        if response.body.key?('error')
          raise ResponseError, "Todoist HTTP response:\n" + response.body.pretty_inspect
        end
      end
  end
end
