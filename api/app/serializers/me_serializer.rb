# Bootstraps the lens UI: current person + alphabetical direct-report
# summaries. Counts come from each report's own frozen snapshot only —
# never cross-person aggregates (D6 / A13).
class MeSerializer
  def self.call(person:)
    new(person: person).as_json
  end

  def initialize(person:)
    @person = person
  end

  def as_json
    {
      "id" => @person.id,
      "name" => @person.name,
      "role" => @person.role,
      "latest_snapshot_id" => latest_snapshot_id_for(@person),
      "reports" => @person.reports.order(:name).map { |report| report_row(report) }
    }
  end

  private

  def report_row(report)
    snapshot = latest_snapshot_for(report)
    {
      "id" => report.id,
      "name" => report.name,
      "latest_snapshot_id" => snapshot&.id,
      "cycle_label" => snapshot&.cycle_label,
      "covered" => snapshot ? Array(snapshot.met).length : nil,
      "total" => snapshot ? Array(snapshot.met).length + Array(snapshot.gap).length : nil
    }
  end

  def latest_snapshot_id_for(person)
    latest_snapshot_for(person)&.id
  end

  def latest_snapshot_for(person)
    person.snapshots.order(closed_at: :desc).first
  end
end
