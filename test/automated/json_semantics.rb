context JsonSemantics do
  module BoolType
    extend self

    def validator
      ValueSemantics::Bool
    end

    def json_coercer
      ->(value) do
        case value
        when 1 then true
        when 0 then false
        else value
        end
      end
    end

    def serialize(value)
      value ? 1 : 0
    end
  end

  class Person
    include JsonSemantics

    json_semantics do
      awake? BoolType, json_key: 'is_awake'
    end
  end

  test "is constructable by attr" do
    person = Person.new(awake?: true)
    assert_eq(person.awake?, true)
  end

  test "is constructable from JSON" do
    person = Person.from_json({ 'is_awake' => false })
    assert_eq(person.awake?, false)
  end

  test "uses the validator from the type" do
    assert_raises(ValueSemantics::InvalidValue) do
      Person.new(awake?: 5)
    end
  end

  test "uses the coercer from the type" do
    assert_eq(Person.new(awake?: 1).awake?, true)
    assert_eq(Person.new(awake?: 0).awake?, false)
  end

  test "exposes a JSON object coercer on the class" do
    assert_eq(
      Person.json_coercer.call({ 'is_awake' => true }),
      Person.new(awake?: true),
    )

    assert_eq(
      Person.coercer.call(66),
      66,
    )
  end

  test "deserialises back to JSON using the type" do
    assert_eq(
      Person.new(awake?: true).to_json_hash,
      { 'is_awake' => 1 },
    )
  end

  test "can use the class as a coercion proc" do
    assert_eq(
      [{ 'is_awake' => 1 }].map(&Person),
      [Person.new(awake?: true)],
    )
  end

  test "supports seamless nesting of types" do
    class Family
      include JsonSemantics

      json_semantics do
        aunty Person
      end
    end

    family_json = { 'aunty' => { 'is_awake' => 1 } }
    family = Family.from_json(family_json)

    assert_is_a(family.aunty, Person)
    assert_eq(family.aunty.awake?, true)
    assert_eq(family.to_json_hash, family_json)
  end

end
