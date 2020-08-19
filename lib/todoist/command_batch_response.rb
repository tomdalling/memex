module Todoist
  class CommandBatchResponse
    include JsonSemantics
    json_semantics do
      temp_id_mapping Types::HashOf[Types::UUID => Types::Id]
      sync_status Types::HashOf[
        Types::UUID => Types::Either[OkStatus, ErrorDetails]
      ]
    end

    def self.ok(commands = [])
      new(
        temp_id_mapping: commands.select(&:temp_id).each_with_index.to_h do |cmd, idx|
          [cmd.temp_id, 6000 + idx]
        end,
        sync_status: commands.to_h do |cmd|
          [cmd.uuid, Todoist::OkStatus]
        end
      )
    end

    def ok?
      sync_status.values.all?(&:ok?)
    end
  end
end
