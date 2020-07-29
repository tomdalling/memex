require_relative '../lib/boot'
require 'test_bench'

TEST_ROOT_DIR = Pathname(__dir__)
TEST_TMP_DIR = TEST_ROOT_DIR / "tmp"

TEST_TMP_DIR.mkdir unless TEST_TMP_DIR.exist?
