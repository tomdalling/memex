module Todoist
  module Commands
  end
end

Pathname(__dir__).glob('commands/**/*.rb') do |path|
  require path
end
