class UUID
  REGEX = %r{
    \A
    [a-z0-9]{8} -
    [a-z0-9]{4} -
    [a-z0-9]{4} -
    [a-z0-9]{4} -
    [a-z0-9]{12}
    \z
  }x

  def self.valid_format?(str)
    REGEX.match?(str)
  end

  def self.random
    new(formatted: SecureRandom.uuid)
  end

  value_semantics do
    formatted REGEX
  end

  def to_s
    formatted
  end

  def inspect
    "#<#{self.class} #{to_s}>"
  end
end
