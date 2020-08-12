class Todoist::Commands::DeleteItem
  value_semantics do
    id Either(Integer, UUID)
    uuid UUID, default_generator: UUID.method(:random)
  end

  def type
    :item_delete
  end

  def args
    { id: id }
  end

  def temp_id
    nil
  end
end
