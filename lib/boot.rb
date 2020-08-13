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

# require gems
require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

# boot stuff that the codebase expects to be globally available
ValueSemantics.monkey_patch!
require_relative 'core_ext'
require_relative 'duck_check'
DuckCheck.monkey_patch!

# load the rest of the codebase
$LOAD_PATH.unshift(__dir__) unless $LOAD_PATH.include?(__dir__)
Dir["#{__dir__}/**/*.rb"].sort.each do |path|
  require path unless path == __FILE__
end
