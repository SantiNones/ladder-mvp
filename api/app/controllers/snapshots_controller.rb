class SnapshotsController < ApplicationController
  before_action :require_current_person!

  def show
    snapshot = Snapshot.find_by(id: params[:id])
    return head :not_found unless snapshot

    visible = VisibilityResolver.call(
      viewer: current_person,
      subject: snapshot.person,
      snapshot: snapshot
    )
    return head :not_found if visible[:access] == :denied

    prompt_payload = PromptPayloadBuilder.call(visible: visible)
    render json: SnapshotSerializer.call(visible: visible, prompt_payload: prompt_payload)
  end
end
