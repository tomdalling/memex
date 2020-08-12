module Journal::CLI
  class Today < Dry::CLI::Command
    desc "Opens the journal entry for today, creating it if it doesn't exist"

    def call
      Journal.edit_date(Date.today)
    end
  end

  class Yesterday < Dry::CLI::Command
    desc "Opens the journal entry for yesterday, creating it if it doesn't exist"

    def call
      Journal.edit_date(Date.today - 1)
    end
  end

  class Tomorrow < Dry::CLI::Command
    desc "Opens the journal entry for tomorrow, creating it if it doesn't exist"

    def call
      Journal.edit_date(Date.today + 1)
    end
  end

  extend Dry::CLI::Registry
  register "today", Today
  register "yesterday", Yesterday
  register "tomorrow", Tomorrow
end
