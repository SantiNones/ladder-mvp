require "test_helper"

class MeControllerTest < ActionDispatch::IntegrationTest
  self.fixture_paths = []
  fixtures []

  setup do
    silence_warnings { load Rails.root.join("db/seeds.rb") }
    @ana = Person.find_by!(name: "Ana Ferrer")
    @laura = Person.find_by!(name: "Laura Puig")
    @carlos = Person.find_by!(name: "Carlos Medina")
    @h1 = Snapshot.find_by!(person: @ana, cycle_label: "H1 2026")
    @laura_h1 = Snapshot.find_by!(person: @laura, cycle_label: "H1 2026")
    @carlos_h1 = Snapshot.find_by!(person: @carlos, cycle_label: "H1 2026")
  end

  test "missing X-Person-Id returns 404" do
    get me_url
    assert_response :not_found
  end

  test "unknown X-Person-Id returns 404" do
    get me_url, headers: { "X-Person-Id" => "999999" }
    assert_response :not_found
  end

  test "Ana sees herself with latest snapshot and empty reports" do
    get me_url, headers: person_header(@ana)
    assert_response :success

    body = JSON.parse(response.body)
    assert_equal @ana.id, body["id"]
    assert_equal "Ana Ferrer", body["name"]
    assert_equal "employee", body["role"]
    assert_equal @h1.id, body["latest_snapshot_id"]
    assert_equal [], body["reports"]
  end

  test "Laura sees reports alphabetically with Ana and Carlos covered counts" do
    get me_url, headers: person_header(@laura)
    assert_response :success

    body = JSON.parse(response.body)
    assert_equal @laura.id, body["id"]
    assert_equal "manager", body["role"]
    assert_equal @laura_h1.id, body["latest_snapshot_id"]

    reports = body["reports"]
    assert_equal ["Ana Ferrer", "Carlos Medina"], reports.map { |r| r["name"] }

    ana_row = reports.find { |r| r["id"] == @ana.id }
    assert_equal @h1.id, ana_row["latest_snapshot_id"]
    assert_equal "H1 2026", ana_row["cycle_label"]
    assert_equal 5, ana_row["covered"]
    assert_equal 10, ana_row["total"]

    carlos_row = reports.find { |r| r["id"] == @carlos.id }
    assert_equal @carlos_h1.id, carlos_row["latest_snapshot_id"]
    assert_equal "H1 2026", carlos_row["cycle_label"]
    assert_equal 2, carlos_row["covered"]
    assert_equal 10, carlos_row["total"]
  end

  private

  def person_header(person)
    { "X-Person-Id" => person.id.to_s }
  end
end
