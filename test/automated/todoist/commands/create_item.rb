context Todoist::Commands::CreateItem do
  test "turns an item into the correct API command JSON" do
    item = Todoist::Item[
      id: 99999,
      content: "AAA",
      project_id: 123,
      parent_id: 999,
      child_order: 333,
      label_ids: [11, 22, 33],
      due: Todoist::Due['2020-01-01'],
    ]

    assert_eq(
      class_under_test.duplicating(item).args,
      {
        content: "AAA",
        project_id: 123,
        parent_id: 999,
        child_order: 333,
        labels: [11, 22, 33],
        due: {
          date: '2020-01-01',
        },
      }
    )
  end
end
