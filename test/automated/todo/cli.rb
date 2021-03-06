RootContext.context Todo::CLI do
  todoist = TodoistClientFake.new
  config = Config::TodoistConfig.new(
    api_token: 'fakepi_token_more_like_it',
    master_checklists_project: 'Master Checklists',
    active_checklists_project: 'Active Checklists',
    checklist_trigger_label: 'Triggo',
  )

  # projects
  p_checklists = todoist.project!("! Master Checklists")
  p_actives = todoist.project!("! Active Checklists")

  # labels
  l_trigger = todoist.label!("Triggo")
  l_other = todoist.label!("Other label")

  # items
  i_recurring = todoist.item!("Stuff", labels: l_trigger, due: 'today')
  i_checklist = todoist.item!("Stuff", project: p_checklists, labels: l_other)
  i_child = todoist.item!("Substuff", parent: i_checklist, labels: l_other)

  # run CLI
  subject = Todo::CLI::Checklist.new(
    todoist_client: todoist,
    todoist_config: config,
    stdout: StringIO.new,
    stderr: StringIO.new,
  )
  subject.()

  # extract commands run
  cmd_check_recurring = todoist.find_cmd(type: :item_close)
  cmd_dup_parent = todoist.find_cmd(type: :item_add, content: /Stuff/)
  cmd_dup_child = todoist.find_cmd(type: :item_add, content: "Substuff")

  test "checks off the recurring item" do
    assert(cmd_check_recurring)
    assert_eq(cmd_check_recurring.id, i_recurring.id)
  end

  test "duplicates the checklist item" do
    assert(cmd_dup_parent)
  end

  test "adds '(checklist)' to the duplicated checklist item" do
    assert_eq(cmd_dup_parent.content, "Stuff (Checklist)")
  end

  test "moves the duplicated items to the 'active checklists' project" do
    assert_eq(cmd_dup_parent.project_id, p_actives.id)
  end

  test "makes the duplicated checklist due today" do
    assert_predicate(cmd_dup_parent.due, :today?)
  end

  test "duplicates child items" do
    assert(cmd_dup_child)
  end

  test "nests duplicated child items" do
    assert_eq(cmd_dup_child.parent_id, cmd_dup_parent.temp_id)
  end

  test "keeps labels on duplicated items" do
    assert_includes(cmd_dup_parent.labels, l_other.id)
    assert_includes(cmd_dup_child.labels, l_other.id)
  end
end
