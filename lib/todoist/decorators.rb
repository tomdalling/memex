module Todoist::Decorators
  # NOTE: could cache and deduplicate decorators for more perf
  def self.decorate(model, everything)
    # TODO: could make this more open/closed
    case model
    when Array then model.map { decorate(_1, everything) }
    when Todoist::Item then self::Item.new(model, everything)
    else model
    end
  end
end

Pathname(__dir__).glob('decorators/**/*.rb') do |path|
  require path
end
