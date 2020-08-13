module VCRMatcher
  extend self

  def call(r1, r2)
    r1.method == r2.method &&
      r1.uri == r2.uri &&
      r1.headers == r2.headers &&
      normalized_body(r1) == normalized_body(r2)
  end

  private
    BASE_UUID = "00000000-0000-4000-b000-000000000000"

    def normalized_body(request)
      if request.headers['Content-Type'].any? { _1.include?('json') }
        deep_scrub_uuids(JSON.parse(request.body))
      else
        request.body
      end
    end

    def deep_scrub_uuids(value, next_uuid = BASE_UUID.dup)
      case value
      when Hash
        value.to_h { [deep_scrub_uuids(_1), deep_scrub_uuids(_2)] }
      when Array
        value.map { deep_scrub_uuids(_1) }
      when String
        if UUID.valid_format?(value)
          next_uuid.succ!.dup
        else
          value
        end
      else
        value
      end
    end
end
