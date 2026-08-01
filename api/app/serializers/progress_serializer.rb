# Shapes one person's own snapshot history for the Progress screen (SPEC §8.3).
# No access checks here — PeopleController already ran VisibilityResolver.
# Counts only, never evidence text or other people's data.
class ProgressSerializer
  def self.call(subject:)
    new(subject: subject).as_json
  end

  def initialize(subject:)
    @subject = subject
    @snapshots = subject.snapshots.order(:window_end)
  end

  def as_json
    {
      "person_id" => @subject.id,
      "person_name" => @subject.name,
      "history" => @snapshots.map { |snapshot| history_row(snapshot) },
      "current" => current_breakdown
    }
  end

  private

  def history_row(snapshot)
    met = Array(snapshot.met)
    gap = Array(snapshot.gap)
    {
      "cycle_label" => snapshot.cycle_label,
      "window_end" => snapshot.window_end.iso8601,
      "covered" => met.length,
      "total" => met.length + gap.length
    }
  end

  # Per-competency covered/total for the most recent snapshot only.
  def current_breakdown
    latest = @snapshots.last
    return nil unless latest

    criteria_by_id = Criterion.where(id: criterion_ids(latest)).index_by(&:id)
    totals = Hash.new { |h, k| h[k] = { "covered" => 0, "total" => 0 } }

    Array(latest.met).each do |row|
      competency = criteria_by_id[row["criterion_id"]]&.competency
      next unless competency

      totals[competency]["covered"] += 1
      totals[competency]["total"] += 1
    end

    Array(latest.gap).each do |row|
      competency = criteria_by_id[row["criterion_id"]]&.competency
      next unless competency

      totals[competency]["total"] += 1
    end

    {
      "cycle_label" => latest.cycle_label,
      "by_competency" => totals.map { |competency, counts| counts.merge("competency" => competency) }
    }
  end

  def criterion_ids(snapshot)
    (Array(snapshot.met) + Array(snapshot.gap)).map { |row| row["criterion_id"] }
  end
end
