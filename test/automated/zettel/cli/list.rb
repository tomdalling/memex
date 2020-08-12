context Zettel::CLI::List do
  def subject
    class_under_test.new(
      zettel_repo: ZettelRepoFake.new,
      relative_to: '',
    )
  end

  test 'lists all zettels' do
    assert_eq(
      run_subject do |repo|
        repo.append(path: "abc.md", title: "Reading")
        repo.append(path: "poe.md", title: "Riting")
        repo.append(path: "123.md", title: "Rithmatic")
      end,
      <<~END_OUTPUT
        abc.md\tabc\tReading
        poe.md\tpoe\tRiting
        123.md\t123\tRithmatic
      END_OUTPUT
    )
  end

  test 'filters by hashtag' do
    assert_eq(
      run_subject(hashtags: '#a') do |repo|
        repo.append(path: "aaa.md", tags: '#a')
        repo.append(path: "bbb.md", tags: '#b')
      end,
      <<~END_OUTPUT
        aaa.md\taaa\tTitle
      END_OUTPUT
    )
  end

  test 'filters by backlinks' do
    assert_eq(
      run_subject(backlinking_to: 'xyz') do |repo|
        repo.append(path: "lnk.md", body: '[link](xyz.md)')
        repo.append(path: "noo.md", tags: '[link](noo.md)')
      end,
      <<~END_OUTPUT
        lnk.md\tlnk\tTitle
      END_OUTPUT
    )
  end

  test 'has a format compatible with vim quickfix window' do
    assert_eq(
      run_subject(format: 'vimgrep') do |repo|
        repo.append(path: "vim.md", title: "Vimmy Wimmy")
      end,
      <<~END_OUTPUT
        vim.md:1:1:# Vimmy Wimmy
      END_OUTPUT
    )
  end

  def run_subject(...)
    capture_stdout do
      s = subject
      yield s.zettel_repo
      s.(...)
    end
  end
end
