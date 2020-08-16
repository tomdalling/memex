module Journal
  extend self

  def edit_date(date)
    path = Memex.journal_dir / date.strftime('%F.md')
    title = date.strftime('%A, %-d %B %Y')
    template = <<~END_TEMPLATE
      #{title}
      #{'=' * title.length}


    END_TEMPLATE

    unless path.exist?
      path.write(template, mode: 'wx') # never overwrites
    end

    system(
      ENV.fetch('EDITOR', 'nvim'),
      '-c', 'normal G$',
      '--', path.to_path,
      chdir: Memex.journal_dir,
    )

    if path.exist? && path.read.strip == template.strip
      puts "Deleting journal entry due to being empty: #{path}"
      path.delete # don't leave behind empty journals
    end
  end
end
