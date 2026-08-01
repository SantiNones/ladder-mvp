class MeController < ApplicationController
  before_action :require_current_person!

  def show
    render json: MeSerializer.call(person: current_person)
  end
end
