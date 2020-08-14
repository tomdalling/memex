module Todoist
  module Client::SyncRead
    implements IEndpoint
    extend self

    def request
      Client::Request.post('/sync/v8/sync',
        resource_types: %w(items labels projects)
      )
    end

    def map_response(response)
      Todoist::Everything.from_json(response.body)
    end
  end
end
