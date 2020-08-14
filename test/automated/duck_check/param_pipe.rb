context DuckCheck::ParamPipe do

  class ParamCompatibilityFixture
    include TestBench::Fixture

    value_semantics do
      parameter String, default: ''
      compatible_with Hash, default: {}
      incompatible_with Hash, default: {}
      untestable ArrayOf(Symbol), default: []
      skip? Bool(), default: false
    end

    def self.build(attrs = nil)
      if attrs
        new(attrs)
      else
        new(skip?: true)
      end
    end

    def call
      return if skip?

      ensure_no_bad_types!
      ensure_all_types_covered!
      ensure_no_types_overlap!

      original = param_list_for(parameter)

      compatible_with.each do |type, substitute_parameter|
        test_compatibility(:assert, original, type, substitute_parameter)
      end

      incompatible_with.each do |type, substitute_parameter|
        test_compatibility(:refute, original, type, substitute_parameter)
      end
    end

    def assert_compatible(**kwargs)
      assfute_compatible(
        :assert,
        **kwargs,
        caller_location: caller_locations.first,
      )
    end

    def refute_compatible(**kwargs)
      assfute_compatible(
        :refute,
        **kwargs,
        caller_location: caller_locations.first,
      )
    end

    private

      def valid_types
        DuckCheck::ParamPipe::Param::TYPES + [:nothing]
      end

      def all_types
        compatible_with.keys + incompatible_with.keys
      end

      def ensure_no_bad_types!
        bad_types = all_types.reject { _1.in?(valid_types) }
        if bad_types.any?
          fail "Not valid param types: " + bad_types.inspect
        end
      end

      def ensure_all_types_covered!
        missing_types = valid_types - all_types - untestable
        if missing_types.any?
          fail "Untested param types: " + missing_types.inspect
        end
      end

      def ensure_no_types_overlap!
        duplicates = all_types.select { all_types.count(_1) > 1 }
        if duplicates.any?
          fail "Param types can not be both compatible AND incompatible: " + duplicates.inspect
        end
      end

      def param_list_for(obj)
        if obj.is_a?(DuckCheck::ParamPipe)
          obj
        elsif obj.is_a?(String)
          mod = Module.new
          mod.module_eval("def test(#{obj}); end")
          DuckCheck::ParamPipe.for_method(mod.instance_method(:test))
        else
          fail "Not a param list: #{obj.inspect}"
        end
      end

      def assfute_compatible(assertion, orig:, subs:, caller_location: nil)
        caller_location ||= caller_locations.first

        original = param_list_for(orig)
        detail "Original: (#{orig}) #{original.inspect}"

        substitute = param_list_for(subs)
        detail "Substitute: (#{subs}) #{substitute.inspect}"

        compat = substitute.compatibility_as_substitute_for(original)
        detail "Compatibility: #{compat.inspect}"

        send(assertion, compat.ok?, caller_location: caller_location)
      end

      def test_compatibility(assertion, original, sub_type, sub_param_string)
        can = assertion == :assert ? "can" : "CAN NOT"
        test "#{can} be substituted with :#{sub_type} param" do
          assfute_compatible(assertion, orig: original, subs: sub_param_string)
        end
      end
  end

  context ':req params' do
    fixture(ParamCompatibilityFixture,
      parameter: 'a',
      compatible_with: {
        req: 'x',
      },
      incompatible_with: {
        opt: 'a = 1',
        rest: '*a',
        keyreq: 'a:',
        key: 'a: 1',
        keyrest: '**a',
        block: '&a',
        nothing: '',
      },
    )
  end

  context ':opt params' do
    fixture(ParamCompatibilityFixture,
      parameter: 'a = 1',
      compatible_with: {
        req: 'x',
        opt: 'x = 2',
        rest: '*args',
      },
      incompatible_with: {
        keyreq: 'a:',
        key: 'a: 1',
        keyrest: '**a',
        block: '&a',
        nothing: '',
      },
    )
  end

  context ':rest params' do
    context 'alone' do
      fixture(ParamCompatibilityFixture,
        parameter: '*args',
        compatible_with: {
          rest: '*stuff',
        },
        incompatible_with: {
          req: 'args',
          opt: 'args = 1',
          keyreq: 'args:',
          key: 'args: 1',
          keyrest: '**args',
          block: '&args',
          nothing: '',
        },
      )
    end

    context 'at the start' do
      fixture(ParamCompatibilityFixture,
        parameter: '*args, z',
        compatible_with: {
          rest: '*stuff, z',
        },
        incompatible_with: {
          req: 'args, z',
          opt: 'args = 1, z',
          nothing: 'z',
        },
        untestable: %i(keyreq key keyrest block),
      )
    end

    context 'in the middle' do
      fixture(ParamCompatibilityFixture,
        parameter: 'a, *args, z',
        compatible_with: {
          rest: 'x, *y, z',
        },
        incompatible_with: {
          req: 'a, args, z',
          opt: 'a, args = 1, z',
          nothing: 'a, z',
        },
        untestable: %i(keyreq key keyrest block),
      )
    end


    context 'at the end' do
      fixture(ParamCompatibilityFixture,
        parameter: 'a, *args',
        compatible_with: {
          rest: 'x, *y',
        },
        incompatible_with: {
          req: 'a, args',
          opt: 'a, args = 1',
          keyreq: 'a, args:',
          key: 'a, args: 1',
          keyrest: 'a, **args',
          block: 'a, &args',
          nothing: 'a',
        },
      )
    end
  end

  context ':keyreq params' do
    fixture(ParamCompatibilityFixture,
      parameter: 'a:',
      compatible_with: {
        keyreq: 'a:',
      },
      incompatible_with: {
        req: 'a',
        opt: 'a = 1',
        rest: '*a',
        key: 'a: 1',
        keyrest: '**a',
        block: '&a',
        nothing: '',
      },
    )
  end

  context ':key params' do
    fixture(ParamCompatibilityFixture,
      parameter: 'a: 1',
      compatible_with: {
        key: 'a: 3',
        keyrest: '**a',
      },
      incompatible_with: {
        req: 'a',
        opt: 'a = 1',
        rest: '*a',
        keyreq: 'a:',
        block: '&a',
        nothing: '',
      },
    )
  end

  context ':keyrest params' do
    fixture(ParamCompatibilityFixture,
      parameter: '**kwargs',
      compatible_with: {
        keyrest: '**options',
      },
      incompatible_with: {
        req: 'kwargs',
        opt: 'kwargs = 1',
        rest: '*kwargs',
        keyreq: 'kwargs:',
        key: 'kwargs: 1',
        block: '&kwargs',
        nothing: '',
      },
    )
  end

  context ':block params' do
    fixture(ParamCompatibilityFixture,
      parameter: '&block',
      compatible_with: {
        block: '&callback',
      },
      incompatible_with: {
        req: 'block',
        opt: 'block = 1',
        rest: '*block',
        keyreq: 'block:',
        key: 'block: 1',
        keyrest: '**block',
        nothing: '',
      },
    )
  end

  context 'no params' do
    fixture(ParamCompatibilityFixture,
      parameter: '',
      compatible_with: {
        opt: 'x = 1',
        rest: '*args',
        key: 'x: 1',
        keyrest: '**kwargs',
        block: '&blk',
        nothing: '',
      },
      incompatible_with: {
        req: 'x',
        keyreq: 'x:',
      }
    )
  end

  fixture(ParamCompatibilityFixture) do |f|
    test 'keyword params are order-independent' do
      f.assert_compatible(
        orig: 'a: 1, b:, c:, d: 2',
        subs: 'c:, b:, d: 5, **kwargs',
      )
    end

    test 'keyword params match based on name' do
      f.refute_compatible(orig: 'a:', subs: 'b:')
      f.refute_compatible(orig: 'a: 1', subs: 'b: 1')
    end

    test 'using all param types' do
      f.assert_compatible(
        orig: 'a, b=1, *c, d:, e:1, **f, &g',
        subs: 'z, y=2, *x, d:, e:2, **w, &v',
      )
    end
  end

end
