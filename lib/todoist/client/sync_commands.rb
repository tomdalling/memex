class Todoist::Client
  module SyncCommands
    extend self

    def request(commands)
      Request.post('/sync/v8/sync',
        commands: commands.map { serialize_cmd(_1) },
      )
    end

    def map_response(response)
      Todoist::CommandBatchResponse.from_json(response.body)
    end

    private

      def serialize_cmd(cmd)
        deep_serialize({
          type: cmd.type,
          args: cmd.args,
          uuid: cmd.uuid,
          **(cmd.temp_id ? { temp_id: cmd.temp_id } : {})
        })
      end

      def deep_serialize(obj)
        case obj
        when String, Symbol, Numeric, true, false, nil
          obj
        when Hash
          obj.to_h { [deep_serialize(_1), deep_serialize(_2)] }
        when Array
          obj.map { deep_serialize(_1) }
        when UUID
          obj.formatted
        else
          fail "Don't know how to serialize: #{obj.inspect}"
        end
      end
  end
end
