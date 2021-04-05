module Reference
  class Metadata
    value_semantics do
      original_filename String
      added_at Time, coerce: ISO8601TimeCoercer, default_generator: Time.method(:now)
      title Either(String, nil), default: nil
      dated Either(Date, nil), default: nil, coerce: ISO8601DateCoercer
      tags Either(ArrayOf(String), nil), default: nil
      notes Either(String, nil), default: nil
      author Either(String, nil), default: nil
      delete_after_ingestion? Bool(), default: false
    end

    def self.from_hash(attr_hash)
      # TODO: this could be way more efficient
      from_yaml(YAML.dump(attr_hash))
    end

    def self.from_yaml(yaml)
      new(YAML.safe_load(yaml, symbolize_names: true))
    end

    def to_yaml
      to_h
        .except(:delete_after_ingestion?)
        .compact
        .then { deep_yamlify(_1) }
        .then { YAML.dump(_1) }
    end

    private

      def deep_yamlify(obj)
        case obj
        when String then obj
        when Symbol then obj.to_s
        when Time then obj.iso8601
        when Date then obj.iso8601
        when Hash then obj.to_h { [deep_yamlify(_1), deep_yamlify(_2)] }
        when Enumerable then obj.map { deep_yamlify(_1) }
        else fail "Can't yamlify: #{obj.inspect}"
        end
      end
  end
end
