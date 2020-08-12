require_relative 'due_date'

module Todoist
  class Due
    include JsonSemantics
    json_semantics do
      due_date DueDate, json_key: 'date'
      string Types::String
      recurring? Types::Bool, json_key: 'is_recurring'
    end

    extend Forwardable
    def_delegators :due_date,
      *%i(type fixed? floating? full_day? time date)

    def self.[](raw_date)
      new(
        due_date: DueDate.new(raw_date),
        string: '',
        recurring?: false,
      )
    end

    def today?
      date == Date.today
    end

    def overdue?
      if full_day?
        date < Date.today
      else
        time < Time.now
      end
    end
  end
end
