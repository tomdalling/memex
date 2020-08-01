class Array
  def pop!
    if size > 0
      pop
    else
      fail "Can not pop an empty array"
    end
  end
end
