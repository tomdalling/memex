class Class
  def value_attrs(&block)
    include(ValueSemantics.for_attributes(&block))
  end
end

class Array
  def pop!
    if size > 0
      pop
    else
      fail "Can not pop an empty array"
    end
  end
end
