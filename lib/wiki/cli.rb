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
      path = (Memex::WIKI_DIR / page).sub_ext('.md')
      unless path.exist?
        path.write(template(page), mode: 'wx') # never overwrite
      end

      system(
        ENV.fetch('EDITOR', 'nvim'),
        '-c', 'normal }',
        '--', path.to_path,
        chdir: Memex::WIKI_DIR,
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

  register "open", Open
end
