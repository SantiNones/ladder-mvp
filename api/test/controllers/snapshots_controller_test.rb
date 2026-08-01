require "test_helper"

class SnapshotsControllerTest < ActionDispatch::IntegrationTest
  self.fixture_paths = []
  fixtures []

  setup do
    silence_warnings { load Rails.root.join("db/seeds.rb") }
    @ana = Person.find_by!(name: "Ana Ferrer")
    @laura = Person.find_by!(name: "Laura Puig")
    @carlos = Person.find_by!(name: "Carlos Medina")
    @diego = Person.find_by!(name: "Diego Rams")
    @h1 = Snapshot.find_by!(person: @ana, cycle_label: "H1 2026")
  end

  test "Ana can read her own snapshot" do
    get snapshot_url(@h1), headers: person_header(@ana)
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal @h1.id, body["id"]
    assert_equal @ana.id, body["person_id"]
  end

  test "Laura can read Ana snapshot as direct manager" do
    get snapshot_url(@h1), headers: person_header(@laura)
    assert_response :success
    assert_equal @h1.id, JSON.parse(response.body)["id"]
  end

  # A10 — served JSON never exposes peer author_id or name
  test "A10: JSON has no author_id or name for peer evidence" do
    get snapshot_url(@h1), headers: person_header(@ana)
    assert_response :success
    body = JSON.parse(response.body)

    peer = all_evidence(body).find { |e| e["author_relation"] == "peer" }
    assert_not_nil peer, "expected peer evidence on Ana H1"
    assert peer["body"].present?
    assert_not peer.key?("author_id")
    assert_not peer.key?("author_name")

    json = response.body
    refute_match(/\b#{Regexp.escape(@carlos.name)}\b/, json)
    # Peer author id must not appear as an author_id value anywhere in the payload.
    author_ids = all_evidence(body).filter_map { |e| e["author_id"] }
    refute_includes author_ids, @carlos.id
  end

  # A11 — Laura requesting Diego (not her report) → 404
  test "A11: Laura requesting Diego snapshot returns 404" do
    diego_snapshot = create_blank_snapshot!(@diego, "H1 2026")

    get snapshot_url(diego_snapshot), headers: person_header(@laura)
    assert_response :not_found
    assert_equal "404", response.code
    refute_equal "403", response.code
  end

  # A12 — Ana requesting Carlos → 404
  test "A12: Ana requesting Carlos snapshot returns 404" do
    carlos_snapshot = create_blank_snapshot!(@carlos, "H1 2026")

    get snapshot_url(carlos_snapshot), headers: person_header(@ana)
    assert_response :not_found
    refute_equal "403", response.code
  end

  # A13 — no endpoint returns aggregates or cross-person comparisons
  test "A13: no endpoint returns aggregates or comparisons between people" do
    paths = Rails.application.routes.routes.map { |route| route.path.spec.to_s }
    forbidden = paths.grep(/compar|rank|aggregat|percentile|average|team_stats|leaderboard/i)
    assert_empty forbidden, "found comparison/aggregate routes: #{forbidden}"

    snapshot_routes = paths.grep(/snapshot/i)
    assert_equal ["/snapshots/:id(.:format)"], snapshot_routes
  end

  private

  def person_header(person)
    { "X-Person-Id" => person.id.to_s }
  end

  def all_evidence(body)
    body.fetch("met", []).flat_map { |row| row.fetch("evidence", []) } +
      body.fetch("gap", []).flat_map { |row| row.fetch("evidence", []) }
  end

  def create_blank_snapshot!(person, cycle_label)
    Snapshot.create!(
      person: person,
      cycle_label: cycle_label,
      window_start: Date.new(2026, 1, 1),
      window_end: Date.new(2026, 6, 30),
      closed_at: Time.utc(2026, 6, 30, 18, 0, 0),
      level_position_at_close: person.level_position,
      target_level_position: person.level_position + 1,
      met: [],
      gap: []
    )
  end
end
