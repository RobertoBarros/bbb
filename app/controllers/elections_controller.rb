class ElectionsController < ApplicationController
  def show
    @election = Election.find(params[:id])
    @candidacies = @election.candidacies.includes(:candidate).order(:id)
  end

  def results
    @election = Election.find(params[:id])
    @candidacies = @election.candidacies.includes(:candidate).order(votes_count: :desc, id: :asc)
    @total_votes = @candidacies.sum(&:votes_count)
  end
end
