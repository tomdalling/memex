class TodoistClientFake < Todoist::Client
  ##############################################################################
  # Faked interface
  ##############################################################################

  def fetch!
    @everything = Todoist::Everything.new(
      items: [],
      labels: [],
      projects: [],
    )
    nil
  end

  def run_commands(*commands)
    @captured_commands.concat(commands.flatten)
    Todoist::CommandBatchResponse.ok(commands.flatten)
  end

  ##############################################################################
  # Methods for use in testing
  ##############################################################################

  attr_reader :captured_commands

  def initialize
    super("faketoken123")
    @captured_commands = []
    fetch! # start with an empty @everything
  end

  def label!(name = "Some_Label")
    Todoist::Label.new(
      id: next_id,
      name: name,
      color: 30,
      deleted?: false,
      favorite?: false,
    ).tap { @everything.labels << _1 }
  end

  def item!(content = "Write a test", labels: [], due: nil, parent: nil, project: nil)
    Todoist::Item.new(
      id: next_id,
      parent_id: parent ? parent.id : nil,
      project_id: project_id_for(project) || next_id,
      content: content,
      due: due_for(due),
      label_ids: Array(labels).map { label_id_for(_1) },
      priority: 4,
      child_order: 0,
      checked?: false,
      deleted?: false,
      collapsed?: false,
      added_at: Time.now,
      completed_at: nil,
    ).tap { @everything.items << _1 }
  end

  def project!(name = "Some Project")
    Todoist::Project.new(
      id: next_id,
      name: name,
    ).tap { @everything.projects << _1 }
  end

  def find_cmd(matchers)
    all_found = captured_commands.select do |cmd|
      matchers.all? do |attr, matcher|
        matcher === cmd.public_send(attr)
      end
    end

    if all_found.size <= 1
      all_found.first
    else
      raise "Found multiple commands that match #{attrs.inspect}"
    end
  end

  private

    def next_id
      @next_id ||= 10000
      @next_id += 1
      @next_id
    end

    def due_for(value)
      case value
      when Todoist::Due then value
      when 'today' then Todoist::Due[Date.today.iso8601]
      when String then Todoist::Due[value]
      when nil then nil
      else fail "Not a Due: #{value.inspect}"
      end
    end

    def label_id_for(value)
      case value
      when Todoist::Label then value.id
      when Integer then value
      when String then everything.label(name: value).id
      when nil then nil
      else fail "Not a Label: #{value.inspect}"
      end
    end

    def item_id_for(value)
      case value
      when Todoist::Item then value.id
      when Integer then value
      when nil then nil
      else fail "Not an Item: #{value.inspect}"
      end
    end

    def project_id_for(value)
      case value
      when Todoist::Project then value.id
      when Integer then value
      when nil then nil
      else fail "Not a Project: #{value.inspect}"
      end
    end
end
