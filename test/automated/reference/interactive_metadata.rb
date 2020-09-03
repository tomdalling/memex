RootContext.context Reference::InteractiveMetadata do
  transcript = TrioTranscript.new(stdin: <<~END_STDIN)
    1
    Pay Ya Bill Bud
    22 feb 2222


    #t1 #t2
  END_STDIN

  templates = [
    Reference::Template.new(name: 'bank_statement'),
    Reference::Template.new(
      name: 'water_bill',
      author: 'Aquaman',
      tags: %w(water bill),
    ),
  ]

  subject = class_under_test.new(templates: templates, **transcript.duo)

  result = subject.(
    path: '/whatever.txt',
    noninteractive_metadata: Reference::Metadata.new(
      original_filename: 'whatever.txt',
      author: 'Tesla',
      notes: 'blah blah',
    ),
  )

  test "prompts for input from stdin" do
    assert_eq(transcript.to_s, <<~END_TRANSCRIPT)
      ==[ /whatever.txt ]========================================================

        0) bank_statement
        1) water_bill

        Template (no template): 1
        Title: Pay Ya Bill Bud
        Dated: 22 feb 2222
        Author (Aquaman): 
        Notes (blah blah): 
        Tags (#water #bill): #t1 #t2
    END_TRANSCRIPT
  end

  test "includes `dated` in the results" do
    assert_eq(result.dated, Date.new(2222, 2, 22))
  end

  test "includes `title` in the results" do
    assert_eq(result.title, "Pay Ya Bill Bud")
  end

  test "includes author in the results (from template)" do
    assert_eq(result.author, "Aquaman")
  end

  test "includes notes in the result (from noninteractive_metadata)" do
    assert_eq(result.notes, "blah blah")
  end

  test "includes tags in the result (from user input)" do
    assert_eq(result.tags, %w(t1 t2))
  end
end
