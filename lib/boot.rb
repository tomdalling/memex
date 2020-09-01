# require standard libraries
require 'date'
require 'open3'
require 'set'
require 'shellwords'
require 'strscan'
require 'tempfile'
require 'yaml'
require 'securerandom'
require 'pp'
require 'pathname'

ENV['BUNDLE_GEMFILE'] ||= Pathname(__dir__).parent.join('Gemfile').to_path

# require gems
require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

# setup zetwork loader
Zeitwerk::Loader.new.tap do |loader|
  loader.inflector.inflect(
    'cli' => 'CLI',
    'uuid' => 'UUID',
    'iso8601_time_coercer' => 'ISO8601TimeCoercer',
    'iso8601_date_coercer' => 'ISO8601DateCoercer',
  )
  loader.push_dir(__dir__)
  loader.setup # ready!
end

# boot stuff that the codebase expects to be globally available
ValueSemantics.monkey_patch!
require_relative 'core_ext'
DuckCheck.monkey_patch!
