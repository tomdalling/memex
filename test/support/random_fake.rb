class RandomFake
  include Random::Formatter

  def initialize
    @canned_results = []
  end

  def bytes(size)
    "\x00"*size
  end
end
