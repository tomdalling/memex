#!/usr/bin/env ruby

require_relative '../lib/boot'

Dry::CLI.new(VersionControl::CLI).call
