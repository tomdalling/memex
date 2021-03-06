module VersionControl::CLI
  extend Dry::CLI::Registry

  class Commit < Dry::CLI::Command
    desc "Commits all changes to the data directory"
    option :m, desc: "Git commit message"

    def call(m: nil)
      VersionControl.commit(message: m)
    end
  end

  class MostFrequentWords < Dry::CLI::Command
    desc "Prints the words most frequently used in the given files"

    def call(args: [])
      paths =
        if args.empty?
          Dir.chdir(Config.instance.volume_root_dir)
          Memex.sh('git add --all')
          VersionControl.changes.map{ Pathname(_1.path) }.select(&:file?)
        else
          args.map{ Pathname(_1) }.select(&:file?)
        end

      pp VersionControl.most_frequent_words(paths)
    end
  end

  register "commit", Commit
  register "words", MostFrequentWords
end
