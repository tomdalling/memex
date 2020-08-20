module Reference
  module CLI
    extend Dry::CLI::Registry
    register "add", Add
  end
end
