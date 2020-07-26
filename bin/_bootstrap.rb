require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

module Memex
  ROOT_DIR = Pathname.new(__dir__).parent.freeze
  VIM_RUNTIME_DIR = ROOT_DIR / "config"

  DATA_DIR = ROOT_DIR / "data"
  ZETTEL_DIR = DATA_DIR / "zettel"
  JOURNAL_DIR = DATA_DIR / "journal"
  WIKI_DIR = DATA_DIR / "wiki"
end
