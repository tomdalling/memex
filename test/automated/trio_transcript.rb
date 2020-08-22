RootContext.context TrioTranscript do
  context 'with underlying IOs' do
    stdout = StringIO.new
    stderr = StringIO.new
    stdin = StringIO.new("5\n")
    subject = class_under_test.new(
      stdin: stdin,
      stdout: stdout,
      stderr: stderr,
    )

    subject.stdout.print("What is 2 + 2? ")
    subject.stdin.gets
    subject.stderr.puts("That was wrong!")

    test "captures a transcript of interleaved input and output" do
      assert_eq(subject.to_s, <<~END_TRANSCRIPT)
        What is 2 + 2? 5
        That was wrong!
      END_TRANSCRIPT
    end

    test "sends stdout output to underlying stdout" do
      assert_eq(stdout.string, "What is 2 + 2? ")
    end

    test "sends stderr output to underlying stderr" do
      assert_eq(stderr.string, "That was wrong!\n")
    end

    test "reads from underlying stdin" do
      assert_predicate(stdin, :eof?)
    end
  end

  context 'without underlying IOs' do
    subject = class_under_test.new

    test "has an empty stdin" do
      assert_predicate(subject.stdin, :eof?)
    end

    test "captures a transcript of interleaved input" do
      subject.stdout.print("What is 4 + 4? ")
      subject.stdin.gets
      subject.stderr.puts("Wut?!")

      assert_eq(subject.to_s, <<~END_TRANSCRIPT)
        What is 4 + 4? Wut?!
      END_TRANSCRIPT
    end
  end

  test "turns stdin strings into IOs" do
    subject = class_under_test.new(stdin: "hello")
    assert_eq(subject.stdin.read, "hello")
  end

  test "has a #trio convenience method for passing kwargs" do
    subject = class_under_test.new
    assert_eq(subject.trio, {
      stdin: subject.stdin,
      stdout: subject.stdout,
      stderr: subject.stderr,
    })
  end

  test "has a #duo convenience method for passing kwargs" do
    subject = class_under_test.new
    assert_eq(subject.duo, {
      stdin: subject.stdin,
      stdout: subject.stdout,
    })
  end
end
