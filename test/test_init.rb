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

require_relative '../lib/boot'

TEST_SUPPORT_DIR.glob('**/*.rb').sort.each { require _1 }

VCR.configure do
  _1.cassette_library_dir = (TEST_ROOT_DIR / 'vcr_cassettes').to_path
  _1.hook_into :faraday
  _1.filter_sensitive_data('<API_TOKEN>') { Config.todoist.api_token }
  _1.default_cassette_options = {
    match_requests_on: [VCRMatcher],
  }
end

RootContext.include(CustomAssertions)
