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

    # D14: once persisted, serve the stored prompt_payload — never rebuild live.
    prompt_payload =
      if snapshot.prompt_payload.present?
        snapshot.prompt_payload
      else
        PromptPayloadBuilder.call(visible: visible)
      end

    render json: SnapshotSerializer.call(visible: visible, prompt_payload: prompt_payload)
  end
end
