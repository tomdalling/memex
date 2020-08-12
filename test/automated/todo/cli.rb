context Todo::CLI do
  todoist = TodoistClientFake.new
  l_checklist = todoist.label!("Checklist")
  l_keep = todoist.label!("Keep")
  i_grandparent = todoist.item!
  i_parent = todoist.item!(
    content: "Stuff",
    labels: [l_checklist, l_keep],
    parent: i_grandparent,
    due: Todoist::Due.today(recurring?: true),
  )
  i_child = todoist.item!(content: "Substuff", parent: i_parent)

  subject = Todo::CLI::Checklist.new(todoist_client: todoist)
  subject.()

  cmd_check = todoist.find_cmd(type: :item_close)
  cmd_parent = todoist.find_cmd(type: :item_add, content: "Stuff")
  cmd_child = todoist.find_cmd(type: :item_add, content: "Substuff")

  test "duplicates the parent item" do
    assert(cmd_parent)
  end

  test "does not set a project for duplicated parent item" do
    assert_nil(cmd_parent.project_id)
  end

  test "orphans the duplicated parent item" do
    assert_nil(cmd_parent.parent_id)
  end

  test "makes the duplicated parent item non-recurring" do
    refute_predicate(cmd_parent.due, :recurring?)
  end

  test "removes the 'Checklist' label from duplicated items" do
    refute_includes(cmd_parent.label_ids, l_checklist.id)
  end

  test "keeps other labels on duplicated items" do
    assert_includes(cmd_parent.label_ids, l_keep.id)
  end

  test "duplicates child items" do
    assert(cmd_child)
  end

  test "nests the duplicated child items" do
    assert_eq(cmd_child.parent_id, cmd_parent.temp_id)
  end

  test "checks off the recurring item" do
    assert(cmd_check)
    assert_eq(cmd_check.id, i_parent.id)
  end
end
