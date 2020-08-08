require 'securerandom'
require 'pp'
require 'test_bench'

TEST_ROOT_DIR = Pathname(__dir__)
TEST_TMP_DIR = (TEST_ROOT_DIR / "tmp").tap do
  _1.mkdir unless _1.exist?
end

require_relative 'support/root_context'
require_relative 'support/custom_assertions'
RootContext.include(CustomAssertions)
RootContext.activate!

require_relative '../lib/boot'
