class ApplicationController < ActionController::API
  private

  # Demo lens stand-in — no real auth. Client sends X-Person-Id.
  def current_person
    @current_person ||= Person.find_by(id: request.headers["X-Person-Id"])
  end

  def require_current_person!
    head :not_found unless current_person
  end
end
