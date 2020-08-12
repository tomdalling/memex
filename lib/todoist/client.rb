module Todoist
  class Client
    def initialize(token)
      @token = token
    end

    def everything
      run_endpoint(Endpoints::Everything)
    end

    private

      def run_endpoint(endpoint)
        req = endpoint.request
        resp = send_request(req)
        endpoint.map_response(resp)
      end

      def send_request(r)
        connection.run_request(
          r.http_method,
          r.path,
          r.params.merge(token: @token),
          r.headers,
        )
      end

      def connection
        @connection ||= Faraday.new(url: 'https://api.todoist.com') do
          _1.request :json
          _1.response :json, parser_options: { symbolize_names: true }
          _1.adapter Faraday.default_adapter
        end
      end

      class Request
        HTTP_METHODS = %i(get post)

        value_semantics do
          http_method Either(*HTTP_METHODS)
          path String
          params Hash, default: {}
          headers Hash, default: {}
        end

        HTTP_METHODS.each do |http_method|
          eval <<~END_METHOD
            def self.#{http_method}(path, **params)
              new(
                http_method: :#{http_method},
                path: path,
                params: params,
              )
            end
          END_METHOD
        end
      end

      module Endpoints
        module Everything
          extend self

          def request
            Request.post('/sync/v8/sync',
              resource_types: %w(items labels)
            )
          end

          def map_response(r)
            Todoist::Everything.from_json(r.body)
          end
        end
      end
  end
end
