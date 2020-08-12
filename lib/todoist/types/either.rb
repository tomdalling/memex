class Todoist::Types::Either
  def self.[](*valid_types)
    new(valid_types)
  end

  def initialize(valid_types)
    @valid_types = valid_types
  end

  def validator
    ->(value) do
      @valid_types.any? { _1.validator === value }
    end
  end

  def coercer
    method(:coerce)
  end

  def coerce(value)
    @valid_types.each do |type|
      coerced_value = type.coercer.(value)
      if type.validator === coerced_value
        return coerced_value
      end
    end

    value
  end

end
