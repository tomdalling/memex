#!/usr/bin/env ruby

require_relative '../lib/boot'

ARGV << "open" if ARGV.empty?
Dry::CLI.new(Zettel::CLI).call
