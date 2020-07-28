require 'date'
require 'open3'
require 'set'
require 'shellwords'

require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

$LOAD_PATH.unshift(__dir__) unless $LOAD_PATH.include?(__dir__)

Dir["#{__dir__}/**/*.rb"].sort.each do |path|
  require path unless path == __FILE__
end
