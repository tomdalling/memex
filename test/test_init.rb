require 'securerandom'
require 'pp'
require 'test_bench'

TEST_ROOT_DIR = Pathname(__dir__)
TEST_SUPPORT_DIR = TEST_ROOT_DIR / 'support'
TEST_TMP_DIR = (TEST_ROOT_DIR / "tmp").tap do
  _1.mkdir unless _1.exist?
end

TEST_SUPPORT_DIR.glob('**/*.rb').sort.each { require _1 }

RootContext.include(CustomAssertions)
RootContext.activate!

require_relative '../lib/boot'
