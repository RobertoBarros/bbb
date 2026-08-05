class ElectionsController < ApplicationController
  def show
    @election = Election.find(params[:id])
    @candidacies = @election.candidacies.includes(:candidate).order(:id)
  end
end
