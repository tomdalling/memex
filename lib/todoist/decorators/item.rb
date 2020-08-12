class Todoist::Decorators::Item < SimpleDelegator
  def initialize(item, everything)
    super(item)
    @everything = everything
  end

  def label?(label_name)
    label = @everything.label(name: label_name)
    label_ids.include?(label.id)
  end

  def labels
    label_ids.map do
      @everything.label(id: _1)
    end
  end

  def children
    @everything.items
      .select { _1.parent_id == id }
      .map { Todoist::Decorators.decorate(_1, @everything) }
  end
end
