# Builds the SPEC §7 prompt shape from an already-filtered VisibilityResolver view.
# Never called with a raw snapshot — only with the visible set.
class PromptPayloadBuilder
  LEVEL_NAMES = {
    2 => "IC2 Software Engineer",
    3 => "IC3 Software Engineer"
  }.freeze

  def self.call(visible:)
    new(visible: visible).call
  end

  def initialize(visible:)
    @visible = visible
    @snapshot = visible[:snapshot]
    @subject = visible[:subject]
    @criteria_by_id = Criterion.where(id: visible[:visible_criterion_ids]).index_by(&:id)
  end

  def call
    {
      "subject_first_name" => @subject.name.split.first,
      "cycle_label" => @snapshot.cycle_label,
      "target_level_name" => level_name(@snapshot.target_level_position),
      "met" => @visible[:met].map { |row| met_entry(row) },
      "gap" => @visible[:gap].map { |row| gap_entry(row) }
    }
  end

  private

  def met_entry(row)
    criterion = @criteria_by_id.fetch(row["criterion_id"])
    {
      "code" => criterion.code,
      "competency" => criterion.competency,
      "text" => criterion.text,
      "evidence" => row["evidence"].map { |e| evidence_entry(e) }
    }
  end

  def gap_entry(row)
    criterion = @criteria_by_id.fetch(row["criterion_id"])
    {
      "code" => criterion.code,
      "competency" => criterion.competency,
      "text" => criterion.text,
      "state" => row["state"]
    }
  end

  def evidence_entry(evidence)
    {
      "source_type" => evidence["source_type"],
      "author_relation" => evidence["author_relation"],
      "body" => evidence["body"]
    }
  end

  def level_name(position)
    LEVEL_NAMES.fetch(position) { "IC#{position} Software Engineer" }
  end
end
