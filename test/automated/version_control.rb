context VersionControl do
  context ".most_frequent_words" do
    def most_frequent_words(text)
      VersionControl.most_frequent_words(text)
    end

    test "counts the words used" do
      assert_eq(
        most_frequent_words("cat cat cat dog dog bird"),
        { 'cat' => 3, 'dog' => 2, 'bird' => 1 },
      )
    end

    test "converts everything to lower case" do
      assert_eq(most_frequent_words("CaT dOg"), { "cat" => 1, "dog" => 1 })
    end

    test "strips punctuation off words" do
      assert_eq(most_frequent_words(<<~PUNK_WORDS), { "cat" => 10 })
        cat, cat. cat? cat: (cat) [cat] "cat" _cat_ *cat* ~~cat~~
      PUNK_WORDS
    end

    test "counts hashtags" do
      assert_eq(most_frequent_words("#cat #cat #cat"), { "#cat" => 3 })
    end

    test "substitutes fancy punctuation for ASCII characters" do
      assert_eq(
        most_frequent_words('bee’s “knees”'),
        { "bee's" => 1, "knees" => 1 }
      )
    end

    test "ignores common words" do
      assert_eq(most_frequent_words("the some was but then"), {})
    end

    test "ignores single letter words" do
      assert_eq(most_frequent_words("x y z"), {})
    end

    test "ignores things that don't look like words" do
      assert_eq(most_frequent_words("123.45 #### $2"), {})
    end

    test "strips out markdown links" do
      assert_eq(most_frequent_words("[text](abc.md)"), { "text" => 1 })
    end

    test "takes the 30 most frequent words" do
      # w1 w2 w2 w3 w3 w3 ... w40
      words = (1..40).map { Array.new(_1, "w#{_1}").join(' ') }.join("\n")
      # { "w11" => 11, "w12" => 12, ..., "w40" => 40 }
      expected = (11..40).to_h { ["w#{_1}", _1] }

      assert_eq(most_frequent_words(words), expected)
    end

    test "orders hash elements by frequency" do
      words = ("cat " * 20) + ("dog " * 10) + ("bird " * 30)
      assert_eq(most_frequent_words(words).to_a, [
        ["bird", 30],
        ["cat", 20],
        ["dog", 10],
      ])
    end
  end

  context '.word_cloud' do
    # word1 word2 word2 word3 word3 word3 ... word40
    input = (1..40).map { Array.new(_1, "word#{_1}").join(' ') }.join("\n")
    # this is a hack because I was too lazy to do DI
    VersionControl.instance_variable_set(:@changed_text, input)
    word_cloud = VersionControl.diff_word_cloud

    test "includes the words in the file" do
      assert_includes(word_cloud, 'word40', 'word39', 'word11')
    end

    test "wraps lines at 72 chars" do
      assert_all(word_cloud.lines) { _1.strip.length <= 72 }
    end

    test "ends with a newline" do
      assert_predicate(word_cloud, :end_with?, "\n")
    end
  end
end

