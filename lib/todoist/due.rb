require_relative 'due_date'

module Todoist
  class Due
    include JsonSemantics
    json_semantics do
      due_date DueDate, json_key: 'date'
      timezone Types::Nilable[Types::String]
      string Types::String
      recurring? Types::Bool, json_key: 'is_recurring'
    end

    extend Forwardable
    def_delegators :due_date,
      *%i(type fixed? floating? full_day? time date)

    def self.[](raw_date, overridden_attrs = {})
      new({
        due_date: DueDate.new(raw_date),
        timezone: nil,
        string: '',
        recurring?: false,
        **overridden_attrs
      })
    end

    def self.today(overridden_attrs = {})
      self[Date.today.iso8601, overridden_attrs]
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

    def to_command_arg(format)
      case format
      when :date then { date: due_date.to_s }
      when :string then { string: string }
      else fail "Not a Due format: #{format.inspect}"
      end
    end
  end
end
