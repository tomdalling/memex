module Todoist::JsonConstructable
  def self.[](json_keys_to_attrs = {})
    Module.new.tap do |m|
      m.singleton_class.define_method(:included) do |base|
        base.const_set(:JsonConstructable_Mixin, m)
        base.const_set(:JSON_KEYS_BY_ATTR, json_keys_to_attrs.invert)
        base.extend(ClassMethods)
      end
    end
  end

  module ClassMethods
    def coerce(json)
      if json.is_a?(Hash)
        new(
          value_semantics.attributes.map(&:name).to_h do |attr_name|
            key = self::JSON_KEYS_BY_ATTR.fetch(attr_name, attr_name)
            [attr_name, json.fetch(key)]
          end
        )
      else
        nil
      end
    end

    def to_proc
      method(:coerce).to_proc
    end
  end
end
