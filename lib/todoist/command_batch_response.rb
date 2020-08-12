require_relative 'ok_status'
require_relative 'error_details'

module Todoist
  class CommandBatchResponse
    include JsonSemantics

    json_semantics do
      temp_id_mapping Types::HashOf[Types::UUID => Types::Id]
      sync_status Types::HashOf[
        Types::UUID => Types::Either[OkStatus, ErrorDetails]
      ]
    end

    def ok?
      sync_status.values.all?(&:ok?)
    end
  end
end
