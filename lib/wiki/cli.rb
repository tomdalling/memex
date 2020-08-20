module Wiki::CLI
  extend Dry::CLI::Registry

  class Open < Dry::CLI::Command
    desc "Opens the wiki in $EDITOR"
    argument :page, default: 'index', desc: "The name of the wiki page to open. Default: `index`"

    example [
      "open          # opens data/wiki/index.md",
      "open horsies  # opens data/wiki/horsies.md",
    ]

    def call(page:, **)
      path = (Config.instance.wiki_dir / page).sub_ext('.md')
      unless path.exist?
        path.write(template(page), mode: 'wx') # never overwrite
      end

      system(
        ENV.fetch('EDITOR', 'nvim'),
        '-c', 'normal }',
        '--', path.to_path,
        chdir: Config.instance.wiki_dir,
      )
    end

    private

      def template(page)
        <<~END_TEMPLATE
          #{page.tr('_', ' ').capitalize}
          #{'=' * page.length}


        END_TEMPLATE
      end
  end

  class Export < Dry::CLI::Command
    desc "Outputs standalone HTML for a wiki page. Requires pandoc."
    argument :page, required: true, desc: 'The name of the wiki page to export'

    example 'export seinfeld_episodes'

    def call(page:, args: [])
      path = (Config.instance.wiki_dir / page).sub_ext('.md')
      cmd = [
        'pandoc',
        '--from', 'markdown_github+yaml_metadata_block+header_attributes+gfm_auto_identifiers',
        '--table-of-contents',
        '--self-contained',
        '--css', (Memex::ROOT_DIR / 'vendor/tufte-css/tufte.min.css').to_path,
        *args,
        '--',
        path.to_path,
      ]
      puts Shellwords.join(cmd)
      exec(*cmd)
    end
  end

  register "open", Open
  register "export", Export
end
