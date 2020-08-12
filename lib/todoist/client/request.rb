class Todoist::Client::Request
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
