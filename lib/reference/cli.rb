module Reference
  module CLI
    extend Dry::CLI::Registry
    register "add", Add
    register "open", Open
    register "list", List
    register "remove", Remove
    register "rename-dated", RenameDated
  end
end
