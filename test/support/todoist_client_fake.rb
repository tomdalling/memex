class TodoistClientFake < Todoist::Client
  ##############################################################################
  # Faked interface
  ##############################################################################

  def fetch!
    @everything = Todoist::Everything.new(
      items: [],
      labels: [],
    )
    nil
  end

  def run_commands(*commands)
    @captured_commands.concat(commands.flatten)
  end

  ##############################################################################
  # Methods for use in testing
  ##############################################################################

  attr_reader :captured_commands

  def initialize
    super("faketoken123")
    @captured_commands = []
  end

  def label!(name)
    Todoist::Label.new(
      id: next_id,
      name: name,
      color: 30,
      deleted?: false,
      favorite?: false,
    ).tap { everything.labels << _1 }
  end

  def item!(content: "Write a test", labels: [], due: nil, parent: nil)
    Todoist::Item.new(
      id: next_id,
      parent_id: parent ? parent.id : nil,
      project_id: 0,
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
    ).tap { everything.items << _1 }
  end

  def find_cmd(attrs)
    all_found = captured_commands.select do |cmd|
      attrs.all? { cmd.public_send(_1) == _2 }
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
      when nil then nil
      when Todoist::Due then value
      when 'today' then Todoist::Due[Date.today.iso8601]
      when String then Todoist::Due[value]
      else fail "Not a Due: #{value.inspect}"
      end
    end

    def label_id_for(value)
      case value
      when Todoist::Label then value.id
      when Integer then value
      when String then everything.label(name: value).id
      else fail "Not a label: #{value.inspect}"
      end
    end

    def item_id_for(value)
      case value
      when Todoist::Item then value.id
      when Integer then value
      else fail "Not an item: #{value.inspect}"
      end
    end
end
