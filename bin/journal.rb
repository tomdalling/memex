#!/usr/bin/env ruby

require_relative '../lib/boot'

ARGV << "today" if ARGV.empty?
Dry::CLI.new(Journal::CLI).call
