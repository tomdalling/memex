module Todoist
  class DueDate
    class_implements IType

    def self.validator
      self
    end

    def self.coercer
      ->(value) do
        if value.is_a?(String) && Date._iso8601(value).any?
          new(value)
        else
          value
        end
      end
    end

    attr_reader :raw

    def initialize(raw)
      @raw = raw
    end

    def type
      if raw.include?('Z')
        :fixed # has date, has time of day, has timezone
      elsif raw.include?('T')
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
      Date.iso8601(raw)
    end

    def time
      if full_day?
        nil
      else
        Time.iso8601(raw)
      end
    end

    def to_s
      raw
    end
  end
end
