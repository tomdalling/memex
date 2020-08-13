module Todo::CLI
  class Checklist < Dry::CLI::Command
    desc "Duplicates recurring checklists that are due today (or overdue), and completes them"

    CHECKLIST_LABEL_NAME = "Checklist"
    CHECKLISTS_PROJECT_NAME = "Checklists"

    def initialize(todoist_client: default_todoist_client, stdout: $stdout, stderr: $stderr)
      @stdout = stdout
      @stderr = stderr
      @todoist_client = todoist_client
    end

    def call
      commands = trigger_items.flat_map do
        commands_for_trigger(_1)
      end

      if commands.empty?
        @stdout.puts "Nothing to duplicate"
      else
        commands.each do |cmd|
          type = cmd.class.to_s.split('::').last
          args = cmd.args.inspect
          @stdout.puts "#{type}: #{args}"
        end
      end

      @stdout.puts "Running commands..."
      response = @todoist_client.run_commands(commands)
      if response.ok?
        @stdout.puts "Done!"
      else
        @stderr.puts "ERROR: " + response.inspect
        exit(1)
      end
    end

    private

      def trigger_items
        @due_checklist_items ||= @todoist_client.items
          .select { _1.label?(CHECKLIST_LABEL_NAME) }
          .select(&:due?)
      end

      def commands_for_trigger(trigger)
        [Todoist::Commands::CompleteItem[trigger]] +
          commands_to_duplicate(
            checklist_item_for_trigger(trigger),
            checklist: true,
          )
      end

      def checklist_item_for_trigger(trigger_item)
        item = @todoist_client
          .project(name: CHECKLISTS_PROJECT_NAME)
          .item(content: trigger_item.content)

        if item
          item
        else
          @stderr.puts("Could not find checklist: #{trigger_item.content}")
          exit(1)
        end
      end

      def duplicate_checklist(item)
        @todoist_client.run_commands(
        )
      end

      def commands_to_duplicate(item, reparent_to_id: item.parent_id, checklist: false)
        parent_cmd = Todoist::Commands::CreateItem.duplicating(item,
          temp_id: UUID.random,
          content: item.content + (checklist ? ' (Checklist)' : ''),
          parent_id: reparent_to_id,
          project_id: item.project_id,
          due: checklist ? Todoist::Due.today : nil,
          label_ids: item.labels
            .reject { _1.name == CHECKLIST_LABEL_NAME }
            .map(&:id),
        )
        child_cmds = item.children.flat_map do |child|
          commands_to_duplicate(child, reparent_to_id: parent_cmd.temp_id)
        end

        [parent_cmd, *child_cmds]
      end

      def default_todoist_client
        Todoist::Client.new(Config[:todoist_api_token])
      end
  end

  extend Dry::CLI::Registry
  register "checklist", Checklist
end
