module ISO8601DateCoercer
  def self.call(obj)
    if obj.is_a?(String)
      Date.iso8601(obj)
    else
      obj
    end
  end
end
