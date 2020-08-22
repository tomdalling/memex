RootContext.context Reference::InteractiveMetadata do
  transcript = TrioTranscript.new(stdin: "2222-02-22\nMe\nnotesss\n#t1 #t2\n")
  subject = class_under_test.new(**transcript.duo)

  result = subject.(
    path: '/whatever.txt',
    noninteractive_metadata: Reference::Metadata.new(
      original_filename: 'whatever.txt',
      author: 'Tesla',
      tags: %w(orig1 orig2),
      notes: 'blah blah',
    ),
  )

  test "prompts for input from stdin" do
    assert_eq(transcript.to_s, <<~END_TRANSCRIPT)
      ==[ /whatever.txt ]========================================================
        Dated: 2222-02-22
        Author (Tesla): Me
        Notes (blah blah): notesss
        Tags (#orig1 #orig2): #t1 #t2
    END_TRANSCRIPT
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
