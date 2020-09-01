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

#TODO: integrate upstream
class ValueSemantics::Recipe
  def without(*attr_names)
    self.class.new(attributes:
      attributes.reject { _1.name.in?(attr_names) }
    )
  end

  def with(&block)
    other = ValueSemantics::DSL.run(&block)
    self.class.new(attributes: attributes + other.attributes)
  end

  def build_module
    ValueSemantics.bake_module(self)
  end
end
