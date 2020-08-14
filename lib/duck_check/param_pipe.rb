module DuckCheck
  # TODO: rename to ParamList
  class ParamPipe
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

    private

      class Compatibility
        attr_reader :original, :substitute

        def initialize(original:, substitute:)
          @original = original.dup
          @substitute = substitute.dup
        end

        def self.for(**kwargs)
          new(**kwargs).tap(&:eliminate_substitutes)
        end

        # NOTE: This implementation is not exactly correct for some param lists
        # involving both :rest and :opt params. Detecting whether the param
        # lists are compatible will still work correctly, but the error
        # messages may be misleading.
        #
        # Consider the param lists:
        #
        #     Original:   a=1, *b, c
        #     Substitute: x, *y, z
        #
        # And how they should match, compared to the current implementation:
        #
        #     Expected: x -> a, y -> b, z -> c
        #     Actual:   x -> c, y -> b, z -> a
        #
        # This is due to :req params "taking precedence" over :opt params.
        #
        # The proper way to do this would be to switch to right-to-left order
        # of elimination at the point where all remaining :req params come
        # after a :rest param -- no precedence required.
        def eliminate_substitutes
          # positional params come first. they must be eliminated IN ORDER.
          eliminate_while(:positional?)

          # :keyreq and :key params always preceed :keyrest
          eliminate_while(:keyreq?, :key?)
          eliminate_while(:keyrest?)

          # block params are always last
          eliminate_while(:block?)
        end

        def ok?
          error_messages.empty?
        end

        def error_messages
          messages = []

          if original.any?
            messages << "does not handle parameters `#{original.to_ruby}` of"
          end

          if not substitute.all_optional?
            messages << "has required parameters `#{substitute.to_ruby}` that are not required in"
          end

          messages
        end

        def inspect
          "#<#{self.class} original=#{original.inspect} substitute=#{substitute.inspect}>"
        end

        private

          def eliminate_while(*predicates)
            while substitute.any?
              sub = substitute.first
              break if predicates.none? { sub.public_send(_1) }

              if send("eliminate_#{sub.type}", sub)
                substitute.delete(sub)
              else
                break # elimination failed
              end
            end
          end

          def eliminate_keyreq(sub)
            original.delete(sub)
          end

          def eliminate_key(sub)
            original.delete(sub)
          end

          def eliminate_keyrest(sub)
            original.delete(original.params_of_type(:key, :keyrest))
            true
          end

          def eliminate_block(sub)
            # methods should only ever have ONE block param
            original.delete(original.params_of_type(:block))
            true
          end

          def eliminate_req(sub)
            if original.any?(:req)
              # first priority: sub for :req params
              original.delete(original.first(:req))
              true
            elsif original.any?(:opt)
              # second priority: sub for :opt params
              original.delete(original.first(:opt))
              true
            elsif original.any? && original.first.rest?
              # lastly: can be absorbed into :rest param
              true
            else
              # otherwise: this :req param can not be eliminated
              false
            end
          end

          def eliminate_opt(sub)
            if original.any? && original.first.type?(:opt)
              original.delete(original.first)
              true
            else
              false
            end
          end

          def eliminate_rest(sub)
            original.delete(original.params_of_type(:opt, :rest))
            true
          end
      end

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
end
