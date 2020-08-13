class Todoist::Client
  module SyncRead
    extend self

    def request
      Request.post('/sync/v8/sync',
        resource_types: %w(items labels projects)
      )
    end

    def map_response(response)
      Todoist::Everything.from_json(response.body)
    end
  end
end
