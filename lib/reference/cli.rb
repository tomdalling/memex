module Reference
  module CLI
    extend Dry::CLI::Registry
    register "add", Add
    register "remove", Remove
  end
end
