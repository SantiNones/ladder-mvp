class PeopleController < ApplicationController
  before_action :require_current_person!

  # S5 — progress history + current per-competency breakdown for a person.
  # Same access rule as SnapshotsController (self or direct manager), no
  # cross-person aggregates: every row here comes from one person's own
  # frozen snapshots (SPEC §6, A13).
  def progress
    subject = Person.find_by(id: params[:id])
    return head :not_found unless subject
    return head :not_found unless VisibilityResolver.person_accessible?(viewer: current_person, subject: subject)

    render json: ProgressSerializer.call(subject: subject)
  end
end
