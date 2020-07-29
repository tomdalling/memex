class Class
  def value_attrs(&block)
    include(ValueSemantics.for_attributes(&block))
  end
end
