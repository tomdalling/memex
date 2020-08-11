require 'date'
require 'open3'
require 'set'
require 'shellwords'
require 'strscan'
require 'tempfile'
require 'yaml'

require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

$LOAD_PATH.unshift(__dir__) unless $LOAD_PATH.include?(__dir__)

require_relative 'core_ext' # the rest of the code expects this

Dir["#{__dir__}/**/*.rb"].sort.each do |path|
  require path unless path == __FILE__
end
