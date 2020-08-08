require 'test_bench'
require 'pp'

require_relative '../lib/boot'
require_relative 'support/root_context'

TEST_ROOT_DIR = Pathname(__dir__)
TEST_TMP_DIR = TEST_ROOT_DIR / "tmp"

TEST_TMP_DIR.mkdir unless TEST_TMP_DIR.exist?

RootContext.activate!
