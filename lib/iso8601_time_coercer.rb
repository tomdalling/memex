module ISO8601TimeCoercer
  def self.call(obj)
    if obj.is_a?(String)
      Time.iso8601(obj)
    else
      obj
    end
  end
end
