require 'securerandom'
require 'pp'
require 'vcr'
require 'test_bench'

TEST_ROOT_DIR = Pathname(__dir__)
TEST_SUPPORT_DIR = TEST_ROOT_DIR / 'support'
TEST_CASSETTE_DIR = TEST_ROOT_DIR / 'vcr_cassettes'
TEST_TMP_DIR = TEST_ROOT_DIR / "tmp"

[TEST_TMP_DIR, TEST_CASSETTE_DIR].each do
  _1.mkdir unless _1.exist?
end

TEST_SUPPORT_DIR.glob('**/*.rb').sort.each { require _1 }

VCR.configure do
  _1.cassette_library_dir = (TEST_ROOT_DIR / 'vcr_cassettes').to_path
  _1.hook_into :faraday
end

RootContext.include(CustomAssertions)
RootContext.activate!

require_relative '../lib/boot'
