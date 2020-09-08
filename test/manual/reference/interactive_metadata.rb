require_relative '../../test_init'

subject = Reference::InteractiveMetadata.new(templates: [
  Reference::Template.new(name: 'bank_statement'),
  Reference::Template.new(
    name: 'water_bill',
    author: 'Aquaman',
    tags: %w(water bill),
  ),
])

result = subject.(
  path: '/whatever.txt',
  noninteractive_metadata: Reference::Metadata.new(
    original_filename: 'whatever.txt',
    author: 'Tesla',
    notes: 'blah blah',
  ),
)

puts
pp result
