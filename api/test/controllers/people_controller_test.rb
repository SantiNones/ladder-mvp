require "test_helper"

class PeopleControllerTest < ActionDispatch::IntegrationTest
  self.fixture_paths = []
  fixtures []

  setup do
    silence_warnings { load Rails.root.join("db/seeds.rb") }
    @ana = Person.find_by!(name: "Ana Ferrer")
    @laura = Person.find_by!(name: "Laura Puig")
    @carlos = Person.find_by!(name: "Carlos Medina")
  end

  test "Ana can read her own progress" do
    get progress_person_url(@ana), headers: person_header(@ana)
    assert_response :success

    body = JSON.parse(response.body)
    assert_equal @ana.id, body["person_id"]
    assert_equal ["H2 2025", "H1 2026"], body["history"].map { |row| row["cycle_label"] }
  end

  test "history covered/total matches SPEC for both of Ana's cycles" do
    get progress_person_url(@ana), headers: person_header(@ana)
    body = JSON.parse(response.body)

    h2 = body["history"].find { |row| row["cycle_label"] == "H2 2025" }
    h1 = body["history"].find { |row| row["cycle_label"] == "H1 2026" }
    assert_equal({ "cycle_label" => "H2 2025", "window_end" => "2025-12-31", "covered" => 2, "total" => 10 }, h2)
    assert_equal({ "cycle_label" => "H1 2026", "window_end" => "2026-06-30", "covered" => 5, "total" => 10 }, h1)
  end

  test "current breakdown matches SPEC §12 shape for Ana's latest cycle" do
    get progress_person_url(@ana), headers: person_header(@ana)
    body = JSON.parse(response.body)

    by_competency = body.dig("current", "by_competency").index_by { |row| row["competency"] }
    assert_equal({ "competency" => "RES", "covered" => 2, "total" => 2 }, by_competency["RES"])
    assert_equal({ "competency" => "DIR", "covered" => 0, "total" => 2 }, by_competency["DIR"])
    assert_equal({ "competency" => "TAL", "covered" => 1, "total" => 2 }, by_competency["TAL"])
    assert_equal({ "competency" => "CUL", "covered" => 1, "total" => 2 }, by_competency["CUL"])
    assert_equal({ "competency" => "CRA", "covered" => 1, "total" => 2 }, by_competency["CRA"])
  end

  test "Laura can read Ana's progress as direct manager" do
    get progress_person_url(@ana), headers: person_header(@laura)
    assert_response :success
    assert_equal @ana.id, JSON.parse(response.body)["person_id"]
  end

  # Mirrors A11/A12 — an unrelated viewer gets 404, never 403.
  test "Carlos requesting Ana's progress returns 404, not 403" do
    get progress_person_url(@ana), headers: person_header(@carlos)
    assert_response :not_found
    refute_equal "403", response.code
  end

  # Mirrors A13 — this endpoint returns one person's own snapshots only, no
  # cross-person aggregate or comparison.
  test "progress payload contains no other person's id or name" do
    get progress_person_url(@ana), headers: person_header(@ana)
    json = response.body

    refute_match(/\b#{Regexp.escape(@laura.name)}\b/, json)
    refute_match(/\b#{Regexp.escape(@carlos.name)}\b/, json)
  end

  private

  def person_header(person)
    { "X-Person-Id" => person.id.to_s }
  end
end
