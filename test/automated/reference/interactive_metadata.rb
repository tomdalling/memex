RootContext.context Reference::InteractiveMetadata do
  stdin = StringIO.new("2222-02-22\nMe\nnotesss\n#t1 #t2\n")
  stdout = StringIO.new

  subject = class_under_test.new(stdin: stdin, stdout: stdout)
  result = subject.(
    path: '/whatever.txt',
    noninteractive_metadata: Reference::Metadata.new(
      original_filename: 'whatever.txt',
      author: 'Tesla',
      tags: %w(orig1 orig2),
      notes: 'blah blah',
    ),
  )

  test "asks for a bunch of stuff" do
    assert_eq(stdout.string, <<~END_OUTPUT.chomp("\n"))
      ==[ /whatever.txt ]========================================================
        Dated:   Author (Tesla):   Notes (blah blah):   Tags (#orig1 #orig2): 
    END_OUTPUT
  end

  test "includes dated in the results" do
    assert_eq(result.dated, Date.new(2222, 2, 22))
  end

  test "includes author in the results" do
    assert_eq(result.author, "Me")
  end

  test "includes notes in the result" do
    assert_eq(result.notes, "notesss")
  end

  test "includes tags in the result" do
    assert_eq(result.tags, %w(t1 t2))
  end
end
