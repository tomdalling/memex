module JsonSemantics
  def self.included(base)
    base.extend(ClassMethods)
    base.include(InstanceMethods)
  end

  module InstanceMethods
    def to_json_hash
      self.class::JSON_ATTRS.to_h do |attr|
        [
          attr.json_key.to_s,
          attr.serialize(self.public_send(attr.name)),
        ]
      end
    end
  end

  module ClassMethods
    def json_semantics(&block)
      dsl = DSL.new
      dsl.instance_eval(&block)
      const_set(:JSON_ATTRS, dsl.attrs)
      include dsl.baked_module
    end

    def from_json(json)
      new(
        self::JSON_ATTRS.reduce({}) do
          _1.merge(_2.slice_from(json))
        end
      )
    end

    def coercer
      ->(json) do
        if json.is_a?(Hash)
          from_json(json)
        else
          json
        end
      end
    end

    def to_proc
      coercer
    end

    def validator
      self
    end

    def serialize(value)
      value.to_json_hash
    end
  end

  class DSL
    attr_reader :attrs

    def initialize
      @attrs = []
    end

    def def_attr(name, type, json_key: name)
      @attrs << Attr.new(name: name, type: type, json_key: json_key)
    end

    def baked_module
      ValueSemantics.bake_module(
        ValueSemantics::Recipe.new(
          attributes: @attrs.map(&:to_value_semantics_attribute),
        )
      )
    end

    def method_missing(method, *args, **kwargs)
      def_attr(method, *args, **kwargs)
    end

    class Attr
      value_semantics do
        name Symbol
        type
        json_key String, coerce: true
      end

      def self.coerce_json_key(value)
        if value.is_a?(Symbol)
          value.to_s
        else
          value
        end
      end

      def to_value_semantics_attribute
        ValueSemantics::Attribute.new(
          name: name,
          validator: type.validator,
          coercer: type.coercer,
        )
      end

      def slice_from(json)
        key =
          if json.key?(json_key)
            json_key
          elsif json.key?(json_key.to_sym)
            json_key.to_sym
          else
            nil
          end

        if key
          { name => json.fetch(key) }
        else
          {}
        end
      end

      def serialize(value)
        type.serialize(value)
      end
    end
  end
end
