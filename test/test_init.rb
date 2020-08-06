require_relative '../lib/boot'
require 'test_bench'

TEST_ROOT_DIR = Pathname(__dir__)
TEST_TMP_DIR = TEST_ROOT_DIR / "tmp"

TEST_TMP_DIR.mkdir unless TEST_TMP_DIR.exist?

(TEST_ROOT_DIR / 'support').glob('**/*.rb') { |path| require path }

class DefaultFixture
  include TestBench::Fixture

  def initialize(block)
    @__block = block
  end

  def call
    instance_eval(&@__block)
  end
end

def context(name, &block)
  TestBench.context(name) do
    fixture(DefaultFixture, block)
  end
end
