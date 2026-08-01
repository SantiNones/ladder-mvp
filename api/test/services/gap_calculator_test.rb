require "test_helper"

class GapCalculatorTest < ActiveSupport::TestCase
  # Seed-backed cases need the demo world; skip empty fixtures.
  self.fixture_paths = []
  fixtures []

  setup do
    silence_warnings { load Rails.root.join("db/seeds.rb") }
    @ana = Person.find_by!(name: "Ana Ferrer")
    @laura = Person.find_by!(name: "Laura Puig")
    @carlos = Person.find_by!(name: "Carlos Medina")
    @h1 = Snapshot.find_by!(person: @ana, cycle_label: "H1 2026")
    @by_code = Criterion.all.index_by(&:code)
  end

  # A1 — seed Ana H1 2026: 5 met, 5 gap
  test "A1: Ana H1 2026 yields 5 met and 5 gap" do
    result = GapCalculator.call(
      person: @ana,
      window_start: @h1.window_start,
      window_end: @h1.window_end
    )

    assert_equal 5, result[:met].size
    assert_equal 5, result[:gap].size
    assert_not result[:at_top_of_framework]
  end

  # A2 — CRA-3.2 is uncorroborated, not met, despite self evidence
  test "A2: CRA-3.2 is gap/uncorroborated not met" do
    result = GapCalculator.call(
      person: @ana,
      window_start: @h1.window_start,
      window_end: @h1.window_end
    )

    cra32_id = @by_code["CRA-3.2"].id
    assert result[:met].none? { |row| row["criterion_id"] == cra32_id }

    cra32_gap = result[:gap].find { |row| row["criterion_id"] == cra32_id }
    assert_not_nil cra32_gap
    assert_equal "uncorroborated", cra32_gap["state"]
    assert_predicate cra32_gap["evidence_ids"], :present?
  end

  # A3 — peer evidence on CRA-3.2 moves it to met
  test "A3: peer evidence on CRA-3.2 moves it to met" do
    Evidence.create!(
      person: @ana,
      criterion: @by_code["CRA-3.2"],
      author: @carlos,
      author_relation: "peer",
      source_type: "peer_feedback",
      body: "Ana's component design held up under review.",
      occurred_on: Date.new(2026, 5, 1)
    )

    result = GapCalculator.call(
      person: @ana,
      window_start: @h1.window_start,
      window_end: @h1.window_end
    )

    cra32_id = @by_code["CRA-3.2"].id
    assert result[:met].any? { |row| row["criterion_id"] == cra32_id }
    assert result[:gap].none? { |row| row["criterion_id"] == cra32_id }
  end

  # A4 — inclusive window_start and window_end; day before/after excluded
  test "A4: evidence on window bounds counts; outside does not" do
    person = Person.create!(name: "Boundary Case", role: "employee", level_position: 2)
    start_criterion = @by_code["DIR-3.1"]
    end_criterion = @by_code["DIR-3.2"]
    window_start = Date.new(2026, 3, 1)
    window_end = Date.new(2026, 3, 31)

    Evidence.create!(
      person: person,
      criterion: start_criterion,
      author: @laura,
      author_relation: "manager",
      source_type: "manager_note",
      body: "On the start boundary.",
      occurred_on: window_start
    )
    Evidence.create!(
      person: person,
      criterion: start_criterion,
      author: @laura,
      author_relation: "manager",
      source_type: "manager_note",
      body: "One day before the window.",
      occurred_on: window_start - 1
    )
    Evidence.create!(
      person: person,
      criterion: end_criterion,
      author: @laura,
      author_relation: "manager",
      source_type: "manager_note",
      body: "On the end boundary.",
      occurred_on: window_end
    )
    Evidence.create!(
      person: person,
      criterion: end_criterion,
      author: @laura,
      author_relation: "manager",
      source_type: "manager_note",
      body: "One day after the window.",
      occurred_on: window_end + 1
    )

    result = GapCalculator.call(
      person: person,
      window_start: window_start,
      window_end: window_end
    )

    dir31 = result[:met].find { |row| row["criterion_id"] == start_criterion.id }
    assert_not_nil dir31
    assert_equal 1, dir31["evidence_ids"].size
    assert_equal window_start, Evidence.find(dir31["evidence_ids"].first).occurred_on

    dir32 = result[:met].find { |row| row["criterion_id"] == end_criterion.id }
    assert_not_nil dir32
    assert_equal 1, dir32["evidence_ids"].size
    assert_equal window_end, Evidence.find(dir32["evidence_ids"].first).occurred_on
  end

  # A5 — top of framework: empty met/gap + flag, no exception
  test "A5: person at top of framework returns empty met/gap with flag" do
    result = GapCalculator.call(
      person: @laura,
      window_start: Date.new(2026, 1, 1),
      window_end: Date.new(2026, 6, 30)
    )

    assert_equal [], result[:met]
    assert_equal [], result[:gap]
    assert result[:at_top_of_framework]
  end

  # Seed fixture lock — calculator matches hand-authored H1 snapshot exactly
  test "seed lock: Ana H1 2026 calculator output matches hand-authored snapshot" do
    result = GapCalculator.call(
      person: @ana,
      window_start: @h1.window_start,
      window_end: @h1.window_end
    )

    assert_equal normalize_met(@h1.met), normalize_met(result[:met])
    assert_equal normalize_gap(@h1.gap), normalize_gap(result[:gap])
    assert_not result[:at_top_of_framework]
  end

  private

  def normalize_met(rows)
    rows.map { |row| stringify_row(row).except("state") }
        .map { |row| row.merge("evidence_ids" => row["evidence_ids"].map(&:to_i).sort) }
        .sort_by { |row| row["criterion_id"].to_i }
  end

  def normalize_gap(rows)
    rows.map { |row| stringify_row(row) }
        .map { |row| row.merge("evidence_ids" => row["evidence_ids"].map(&:to_i).sort) }
        .sort_by { |row| row["criterion_id"].to_i }
  end

  def stringify_row(row)
    row.to_h.transform_keys(&:to_s).slice("criterion_id", "state", "evidence_ids")
  end
end
