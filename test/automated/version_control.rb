require_relative '../init'

TestBench.context VersionControl do

  context ".most_frequent_words" do
    subject = ->(file_content) do
      tempfile = Tempfile.new
      begin
        tempfile.write(file_content)
        tempfile.close
        VersionControl.most_frequent_words([tempfile.path])
      ensure
        tempfile.close
        tempfile.unlink
      end
    end

    test "counts the words used" do
      assert(
        subject.("cat cat cat dog dog bird") \
        == { 'cat' => 3, 'dog' => 2, 'bird' => 1}
      )
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
end
