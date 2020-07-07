#!/usr/bin/env ruby

require_relative '_bootstrap'

module Zettle
  extend self

  IDENTIFIER_CHARS = ('a'..'z').to_a + ('0'..'9').to_a
  ZETTLE_DIR = Pathname(__dir__) / "../zettle"

  def new_identifier
    loop do
      identifier = IDENTIFIER_CHARS.sample(3).join
      return identifier unless exists?(identifier)
    end
  end

  def new_path
    path(new_identifier)
  end

  def exists?(identifier)
    path(identifier).exist?
  end

  def path(identifier)
    ZETTLE_DIR.join(identifier).sub_ext(".md")
  end
end


module Zettle::CLI
  extend Dry::CLI::Registry

  class New < Dry::CLI::Command
    desc "Creates a new zettle file and opens it for editing"

    def call
      path = Zettle.new_path
      template = <<~END_TEMPLATE
        # Title goes here
        Tags: #unprocessed
      END_TEMPLATE
      path.write(template, mode: 'wx') # never overwrites

      system(ENV.fetch("EDITOR"), path.to_path)

      if path.read.strip == template.strip
        puts "Deleting new zettle due to being empty"
        path.delete
      end
    end
  end

  register "new", New
end


Dry::CLI.new(Zettle::CLI).call
