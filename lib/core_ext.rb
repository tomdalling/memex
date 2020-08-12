class Array
  def pop!
    if size > 0
      pop
    else
      fail "Can not pop an empty array"
    end
  end
end

class Hash
  def except(*keys)
    reject { keys.include?(_1) }
  end
end

class Object
  def in?(collection)
    collection.include?(self)
  end
end
