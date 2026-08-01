# Shapes an already-filtered VisibilityResolver result for JSON.
# No access checks and no field filtering — that belongs in VisibilityResolver.
class SnapshotSerializer
  def self.call(visible:, prompt_payload:)
    new(visible: visible, prompt_payload: prompt_payload).as_json
  end

  def initialize(visible:, prompt_payload:)
    @visible = visible
    @prompt_payload = prompt_payload
    @snapshot = visible[:snapshot]
    @subject = visible[:subject]
    @criteria_by_id = Criterion.where(id: visible[:visible_criterion_ids]).index_by(&:id)
  end

  def as_json
    {
      "id" => @snapshot.id,
      "person_id" => @subject.id,
      "person_name" => @subject.name,
      "cycle_label" => @snapshot.cycle_label,
      "window_start" => @snapshot.window_start.iso8601,
      "window_end" => @snapshot.window_end.iso8601,
      "closed_at" => @snapshot.closed_at.iso8601,
      "level_position_at_close" => @snapshot.level_position_at_close,
      "target_level_position" => @snapshot.target_level_position,
      "met" => @visible[:met].map { |row| criterion_row(row) },
      "gap" => @visible[:gap].map { |row| criterion_row(row) },
      "narrative" => parsed_narrative,
      "prompt_payload" => @prompt_payload
    }
  end

  private

  def parsed_narrative
    raw = @snapshot.narrative
    return nil if raw.blank?

    raw.is_a?(String) ? JSON.parse(raw) : raw
  rescue JSON::ParserError
    nil
  end

  def criterion_row(row)
    criterion = @criteria_by_id.fetch(row["criterion_id"])
    out = {
      "criterion_id" => row["criterion_id"],
      "code" => criterion.code,
      "competency" => criterion.competency,
      "text" => criterion.text,
      "evidence" => row["evidence"]
    }
    out["state"] = row["state"] if row.key?("state")
    out
  end
end
