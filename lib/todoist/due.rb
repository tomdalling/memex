module Todoist
  class Due
    include JsonConstructable[
      :is_recurring => :recurring?,
      :date => :raw_date,
    ]

    def self.[](raw_date, string: '', recurring: false)
      new(
        raw_date: raw_date,
        string: string,
        recurring?: recurring,
      )
    end

    value_semantics do
      raw_date  String
      string  String
      recurring?  Bool()
    end

    def type
      if raw_date.include?('Z')
        :fixed # has date, has time of day, has timezone
      elsif raw_date.include?('T')
        :floating # has date, has time of day, no timezone
      else
        :full_day # has date, no time of day, no timezone
      end
    end

    def fixed?
      type == :fixed
    end

    def floating?
      type == :floating
    end

    def full_day?
      type == :full_day
    end

    def date
      Date.iso8601(raw_date)
    end

    def today?
      date == Date.today
    end

    def time
      if full_day?
        nil
      else
        Time.iso8601(raw_date)
      end
    end
  end
end
