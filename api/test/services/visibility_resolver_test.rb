require "test_helper"

class VisibilityResolverTest < ActiveSupport::TestCase
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

  test "self and direct manager are allowed; unrelated viewers are denied" do
    assert_equal :allowed, VisibilityResolver.call(viewer: @ana, subject: @ana, snapshot: @h1)[:access]
    assert_equal :allowed, VisibilityResolver.call(viewer: @laura, subject: @ana, snapshot: @h1)[:access]
    assert_equal :denied, VisibilityResolver.call(viewer: @carlos, subject: @ana, snapshot: @h1)[:access]
    assert_equal :denied, VisibilityResolver.call(viewer: @diego, subject: @ana, snapshot: @h1)[:access]
  end

  test "peer evidence keeps body but strips author_id and author_name" do
    visible = VisibilityResolver.call(viewer: @ana, subject: @ana, snapshot: @h1)
    peer = visible[:met].flat_map { |row| row["evidence"] }
                        .find { |e| e["author_relation"] == "peer" }

    assert_not_nil peer
    assert peer["body"].present?
    assert_nil peer["author_id"]
    assert_nil peer["author_name"]
    assert_not peer.key?("author_id")
    assert_not peer.key?("author_name")
  end

  test "manager and hr evidence keep author identity" do
    visible = VisibilityResolver.call(viewer: @laura, subject: @ana, snapshot: @h1)
    manager_ev = visible[:met].flat_map { |row| row["evidence"] }
                              .find { |e| e["author_relation"] == "manager" }
    hr_ev = visible[:met].flat_map { |row| row["evidence"] }
                         .find { |e| e["author_relation"] == "hr" }

    assert_equal @laura.id, manager_ev["author_id"]
    assert_equal "Laura Puig", manager_ev["author_name"]
    assert_equal Person.find_by!(name: "Marta Solé").id, hr_ev["author_id"]
    assert_equal "Marta Solé", hr_ev["author_name"]
  end

  # A8 — prompt_payload contains no criterion outside the visible set
  test "A8: prompt_payload has no criterion outside the visible set" do
    visible = VisibilityResolver.call(viewer: @ana, subject: @ana, snapshot: @h1)
    payload = PromptPayloadBuilder.call(visible: visible)

    visible_codes = Criterion.where(id: visible[:visible_criterion_ids]).pluck(:code).sort
    payload_codes = (
      payload["met"].map { |row| row["code"] } +
      payload["gap"].map { |row| row["code"] }
    ).sort

    assert_equal visible_codes, payload_codes
    assert_no_criterion_ids_in(payload)

    # Inject a criterion the resolver never saw — builder must not invent it into payload.
    outsider = Criterion.find_by!(code: "RES-2.1")
    assert_not_includes visible[:visible_criterion_ids], outsider.id
    assert payload_codes.none? { |code| code == outsider.code }
  end

  private

  def assert_no_criterion_ids_in(node, path = "$")
    case node
    when Hash
      node.each do |key, value|
        refute_equal "criterion_id", key.to_s, "leaked criterion_id at #{path}"
        assert_no_criterion_ids_in(value, "#{path}.#{key}")
      end
    when Array
      node.each_with_index { |value, i| assert_no_criterion_ids_in(value, "#{path}[#{i}]") }
    end
  end
end
