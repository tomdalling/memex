module Todo::CLI
  class Checklist < Dry::CLI::Command
    desc "Duplicates checklists in Todoist"
    argument :checklist_name, desc: <<~END_DESC.strip.gsub(/\s+/, ' ')
      The name of the checklist to dupe. Must exist as a root item in the
      master checklists project project. If not given, will look for items with
      a trigger label that are due today, complete them, then dupe a checklist
      with the same name.
    END_DESC

    def initialize(
      todoist_client: nil,
      todoist_config: nil,
      stdout: $stdout,
      stderr: $stderr
    )
      @stdout = stdout
      @stderr = stderr
      @todoist_config = todoist_config || Config.todoist
      @todoist_client = todoist_client || Todoist::Client.new(@todoist_config.api_token)
    end

    def call(checklist_name: nil, **)
      puts "Loading Todoist data..."

      commands =
        if checklist_name
          commands_for(checklist_name)
        else
          commands_for_autodetected
        end

      if commands.empty?
        puts "Nothing to duplicate"
        return
      end

      commands.each do |cmd|
        type = cmd.class.to_s.split('::').last
        args = cmd.args.inspect
        puts "#{type}: #{args}"
      end

      puts "Running commands..."
      response = @todoist_client.run_commands(commands)
      if response.ok?
        puts "Done!"
      else
        @stderr.puts "ERROR: " + response.inspect
        exit(1)
      end
    end

    private

      def puts(...)
        @stdout.puts(...)
      end

      def commands_for(checklist_name)
        checklist = find_checklist_by_name(checklist_name)
        if checklist
          commands_to_duplicate(checklist, checklist: true)
        else
          @stderr.puts("ERROR: Could not find checklist: #{checklist_name}")
          []
        end
      end

      def commands_for_autodetected
        triggers = @todoist_client.items
          .select { _1.label?(trigger_label) }
          .select(&:due?)

        triggers.flat_map do |t|
          dup_commands = commands_for(t.content)
          if dup_commands.any?
            dup_commands + [Todoist::Commands::CompleteItem[t]]
          else
            []
          end
        end
      end

      def find_checklist_by_name(name)
        master_checklists_project.items
          .reject(&:subitem?)
          .find { fuzzy_match?(_1.content, name) }
      end

      def fuzzy_match?(str1, str2)
        [str1, str2]
          .map(&:downcase)
          .map { _1.gsub(/[^a-z0-9]+/, '') }
          .reduce(:==)
      end

      def commands_to_duplicate(item, reparent_to_id: item.parent_id, checklist: false)
        parent_cmd = Todoist::Commands::CreateItem.duplicating(item,
          temp_id: UUID.random,
          content: item.content + (checklist ? ' (Checklist)' : ''),
          parent_id: reparent_to_id,
          project_id: project_for_active_checklists.id,
          due: checklist ? Todoist::Due.today : nil,
        )
        child_cmds = item.children.flat_map do |child|
          commands_to_duplicate(child, reparent_to_id: parent_cmd.temp_id)
        end

        [parent_cmd, *child_cmds]
      end

      def trigger_label
        @todoist_client.label(@todoist_config.checklist_trigger_label).tap do |label|
          if label.nil?
            raise "Trigger label not found: #{@todoist_config.checklist_trigger_label}"
          end
        end
      end

      def master_checklists_project
        @todoist_client.projects.find do
          fuzzy_match?(_1.name, @todoist_config.master_checklists_project)
        end.tap do |proj|
          if proj.nil?
            raise "Master checklists project not found: #{@todoist_config.master_checklists_project}"
          end
        end
      end

      def project_for_active_checklists
        @todoist_client.projects.find do
          fuzzy_match?(_1.name, @todoist_config.active_checklists_project)
        end.tap do |proj|
          if proj.nil?
            raise "Project for active checklists not found: #{@todoist_config.active_checklists_project}"
          end
        end
      end
  end

  extend Dry::CLI::Registry
  register "checklist", Checklist
end
