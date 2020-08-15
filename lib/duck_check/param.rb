module DuckCheck
  class Param
    TYPES = %i(req opt rest keyreq key keyrest block)

    value_semantics do
      type Either(*TYPES)
      name Either(Symbol, nil)
    end

    def self.from_method_parameter(parameter)
      new(type: parameter[0], name: parameter[1])
    end

    def type?(*types)
      types.include?(type)
    end

    def positional?
      type?(:req, :opt, :rest)
    end

    def optional?
      # blocks should be treated as required, even though they default to nil
      type?(:opt, :rest, :key, :keyrest)
    end

    TYPES.each do |type|
      eval <<~END_METHOD
        def #{type}?
          type == :#{type}
        end
      END_METHOD
    end

    def inspect
      "Param[#{type.inspect}, #{name.inspect}]"
    end

    def to_ruby
      case type
      when :req then name.to_s
      when :opt then "#{name} = <DEFAULT>"
      when :rest then "*#{name}"
      when :keyreq then "#{name}:"
      when :key then "#{name}: <DEFAULT>"
      when :keyrest then "**#{name}"
      when :block then "&#{name}"
      else "<#{type}>#{name}"
      end
    end
  end
end
