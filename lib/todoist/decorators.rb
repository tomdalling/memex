module Todoist::Decorators
end

Pathname(__dir__).glob('decorators/**/*.rb') do |path|
  require path
end
