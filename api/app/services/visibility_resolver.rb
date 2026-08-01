# Access + field visibility for a snapshot viewer. No HTTP, no session.
# Runs before any payload is built or serialized. See SPEC.md §6.
class VisibilityResolver
  def self.call(viewer:, subject:, snapshot:)
    new(viewer: viewer, subject: subject, snapshot: snapshot).call
  end

  # Same access rule as #call, exposed for endpoints that need a person-level
  # check without a specific snapshot in hand (S5 progress history).
  # Single source of truth so the rule never drifts between the two call sites.
  def self.person_accessible?(viewer:, subject:)
    viewer.id == subject.id || subject.manager_id == viewer.id
  end

  def initialize(viewer:, subject:, snapshot:)
    @viewer = viewer
    @subject = subject
    @snapshot = snapshot
  end

  def call
    return { access: :denied } unless accessible?

    evidences_by_id = load_evidences_by_id
    met = decorate_rows(@snapshot.met, evidences_by_id)
    gap = decorate_rows(@snapshot.gap, evidences_by_id)
    visible_criterion_ids = (met + gap).map { |row| row["criterion_id"] }.uniq

    {
      access: :allowed,
      subject: @subject,
      snapshot: @snapshot,
      visible_criterion_ids: visible_criterion_ids,
      met: met,
      gap: gap
    }
  end

  private

  def accessible?
    self.class.person_accessible?(viewer: @viewer, subject: @subject)
  end

  def load_evidences_by_id
    ids = collect_evidence_ids
    return {} if ids.empty?

    Evidence.where(id: ids).includes(:author).index_by(&:id)
  end

  def collect_evidence_ids
    rows = Array(@snapshot.met) + Array(@snapshot.gap)
    rows.flat_map { |row| Array(stringify_keys(row)["evidence_ids"]) }.map(&:to_i).uniq
  end

  def decorate_rows(rows, evidences_by_id)
    Array(rows).map do |row|
      data = stringify_keys(row)
      criterion_id = data["criterion_id"].to_i
      evidence_ids = Array(data["evidence_ids"]).map(&:to_i)

      decorated = {
        "criterion_id" => criterion_id,
        "evidence" => evidence_ids.filter_map { |id| filter_evidence(evidences_by_id[id]) }
      }
      decorated["state"] = data["state"] if data.key?("state")
      decorated
    end
  end

  # Peer authorship is stripped for every viewer — no exceptions (SPEC §6 / S7).
  def filter_evidence(evidence)
    return nil unless evidence

    filtered = {
      "id" => evidence.id,
      "body" => evidence.body,
      "source_type" => evidence.source_type,
      "author_relation" => evidence.author_relation,
      "occurred_on" => evidence.occurred_on.iso8601
    }

    unless evidence.author_relation == "peer"
      filtered["author_id"] = evidence.author_id
      filtered["author_name"] = evidence.author.name
    end

    filtered
  end

  def stringify_keys(row)
    row.to_h.transform_keys(&:to_s)
  end
end
