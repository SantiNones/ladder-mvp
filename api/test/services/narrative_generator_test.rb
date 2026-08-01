require "test_helper"

class NarrativeGeneratorTest < ActiveSupport::TestCase
  self.fixture_paths = []
  fixtures []

  setup do
    silence_warnings { load Rails.root.join("db/seeds.rb") }
    @ana = Person.find_by!(name: "Ana Ferrer")
    @h1 = Snapshot.find_by!(person: @ana, cycle_label: "H1 2026")
    visible = VisibilityResolver.call(viewer: @ana, subject: @ana, snapshot: @h1)
    @payload = PromptPayloadBuilder.call(visible: visible)
  end

  test "template narrative is schema-valid for Ana H1" do
    result = NarrativeGenerator.call(prompt_payload: @payload)

    assert_equal NarrativeGenerator::ALLOWED_KEYS.sort, result.keys.sort
    assert_includes NarrativeGenerator::COMPETENCIES, result["focus_competency"]
    gap_codes = @payload["gap"].map { |row| row["code"] }
    result["next_steps"].each do |step|
      assert_includes gap_codes, step["criterion_code"]
    end
  end

  # A7 — output schema has no level / readiness / score / verdict field
  test "A7: schema has no level, readiness, score, or verdict field" do
    result = NarrativeGenerator.call(prompt_payload: @payload)

    NarrativeGenerator::FORBIDDEN_KEYS.each do |key|
      refute_includes NarrativeGenerator::ALLOWED_KEYS, key
      refute result.key?(key), "narrative must not expose #{key}"
    end

    assert_equal %w[focus_competency next_steps summary], result.keys.sort
  end

  # A9 — invented criterion_code in next_steps triggers fallback
  test "A9: invented criterion_code in next_steps triggers fallback" do
    bad = {
      "summary" => "Invented suggestion that must be rejected.",
      "focus_competency" => "DIR",
      "next_steps" => [
        { "criterion_code" => "FAKE-9.9", "suggestion" => "Do something invented." }
      ]
    }

    result = NarrativeGenerator.call(prompt_payload: @payload, candidate: bad)

    refute_equal bad["summary"], result["summary"]
    gap_codes = @payload["gap"].map { |row| row["code"] }
    result["next_steps"].each do |step|
      assert_includes gap_codes, step["criterion_code"]
    end
    refute_includes result["next_steps"].map { |s| s["criterion_code"] }, "FAKE-9.9"
  end

  # A14 — unexpected error inside generator still yields fallback (D15 adaptation)
  test "A14: unexpected error inside NarrativeGenerator still yields fallback" do
    generator = NarrativeGenerator.new(prompt_payload: @payload)
    generator.define_singleton_method(:build_from_template) do
      raise "simulated internal failure"
    end

    result = generator.call

    assert_equal NarrativeGenerator::ALLOWED_KEYS.sort, result.keys.sort
    assert_includes NarrativeGenerator::COMPETENCIES, result["focus_competency"]
    gap_codes = @payload["gap"].map { |row| row["code"] }
    result["next_steps"].each do |step|
      assert_includes gap_codes, step["criterion_code"]
    end
  end
end
