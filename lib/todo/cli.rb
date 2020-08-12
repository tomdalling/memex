module Todo::CLI
  class Checklist < Dry::CLI::Command
    desc "Duplicates recurring checklists that are due today (or overdue), and completes them"

    CHECKLIST_LABEL_NAME = "Checklist"

    def initialize(todoist_client: default_todoist_client)
      @todoist_client = todoist_client
    end

    def call
      due_checklist_items.each do
        puts "Duplicating checklist: #{_1.content}"
        duplicate_checklist(_1)
        puts "OK"
      end

      if due_checklist_items.empty?
        puts "No appropriate checklists found"
      end
    end

    private

      def due_checklist_items
        @due_checklist_items ||= @todoist_client.items
          .select { _1.label?("Checklist") }
          .select(&:due?)
      end

      def duplicate_checklist(item)
        @todoist_client.run_commands(
          Todoist::Commands::CompleteItem[item],
          commands_to_duplicate(item, reparent_to_id: nil),
        )
      end

      def commands_to_duplicate(item, reparent_to_id: item.parent_id)
        parent_cmd = Todoist::Commands::CreateItem.duplicating(item,
          temp_id: UUID.random,
          parent_id: reparent_to_id,
          project_id: nil,
          due: item.due&.with(recurring?: false),
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
