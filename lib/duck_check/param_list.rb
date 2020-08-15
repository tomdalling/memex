module DuckCheck
  class ParamList
    def self.for_method(method)
      new(
        method.parameters.map { Param.from_method_parameter(_1) }
      )
    end

    def self.empty
      new([])
    end

    def initialize(params)
      @params = params
    end

    def dup
      self.class.new(@params.dup)
    end

    def all_optional?
      @params.all?(&:optional?)
    end

    def any?(*types)
      if types.empty?
        @params.any?
      else
        params_of_type(*types).any?
      end
    end

    def first(*types)
      if types.empty?
        @params.first
      else
        params_of_type(*types).first
      end
    end

    def empty?
      @params.empty?
    end

    def params_of_type(*types)
      @params.select { _1.type.in?(types) }
    end

    def delete(*params)
      @params.reject! { _1.in?(params.flatten) }
    end

    def compatibility_as_substitute_for(other)
      Compatibility.for(original: other, substitute: self)
    end

    def inspect
      params = empty? ? '' : ' ' + @params.map(&:inspect).join(" ")
      "#<#{self.class}#{params}>"
    end

    def to_ruby
      '(' + @params.map(&:to_ruby).join(', ') + ')'
    end
  end
end
