module Todoist
  module Types
  end
end

Pathname(__dir__).glob('types/**/*.rb') do |path|
  require path
end
