require_relative '../init'

TestBench.context VersionControl do
  with_file = ->(file_content, &block) do
    tempfile = Tempfile.new
    begin
      tempfile.write(file_content)
      tempfile.close
      return block.call(tempfile.path)
    ensure
      tempfile.close
      tempfile.unlink
    end
  end

  context ".most_frequent_words" do
    subject = ->(file_content) do
      with_file.(file_content) do |path|
        VersionControl.most_frequent_words([path])
      end
    end

    test "counts the words used" do
      assert(subject.("cat cat cat dog dog bird") == {
        'cat' => 3,
        'dog' => 2,
        'bird' => 1,
      })
    end

    test "converts everything to lower case" do
      assert(subject.("CaT dOg") == { "cat" => 1, "dog" => 1 })
    end

    test "strips punctuation off words" do
      assert(subject.('cat, cat. cat? cat: (cat) [cat] "cat"') == { "cat" => 7 })
    end

    test "counts hashtags" do
      assert(subject.("#cat #cat #cat") == { "#cat" => 3 })
    end

    test "substitutes fancy punctuation for ASCII characters" do
      assert(subject.('bee’s “knees”') == { "bee's" => 1, "knees" => 1 })
    end

    test "ignores common words" do
      assert(subject.("the some was but then") == {})
    end

    test "ignores single letter words" do
      assert(subject.("x y z") == {})
    end

    test "ignores things that don't look like words" do
      assert(subject.("123.45 #### $2") == {})
    end

    test "takes the 30 most frequent words" do
      # w1 w2 w2 w3 w3 w3 ... w40
      words = (1..40).map { Array.new(_1, "w#{_1}").join(' ') }.join("\n")
      # { "w11" => 11, "w12" => 12, ..., "w40" => 40 }
      expected = (11..40).to_h { ["w#{_1}", _1] }

      assert(subject.(words) == expected)
    end

    test "orders hash elements by frequency" do
      words = ("cat " * 20) + ("dog " * 10) + ("bird " * 30)
      assert(subject.(words).to_a == [
        ["bird", 30],
        ["cat", 20],
        ["dog", 10],
      ])
    end
  end

  context '.word_cloud' do
    # word1 word2 word2 word3 word3 word3 ... word40
    input = (1..40).map { Array.new(_1, "word#{_1}").join(' ') }.join("\n")
    subject = with_file.(input) do |path|
      VersionControl.word_cloud([path])
    end

    test "includes the words in the file" do
      assert(subject.include?("word40"))
      assert(subject.include?("word39"))
      assert(subject.include?("word11"))
    end

    test "wraps lines at 72 chars" do
      assert(subject.lines.count > 1)
      assert(subject.lines.all? { _1.strip.length <= 72 })
    end

    test "ends with a newline" do
      assert(subject.end_with?("\n"))
    end
  end
end
