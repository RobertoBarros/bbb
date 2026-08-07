class ElectionsController < ApplicationController
  def index
    respond_to do |format|
      format.json do
        elections = Election.order(:id).map { |election| { id: election.id, title: election.title, status: election.status } }
        render json: { elections: }
      end
    end
  end

  def show
    @election = Election.find(params[:id])

    respond_to do |format|
      format.html do
        @candidacies = @election.candidacies.includes(:candidate).order(:id)
      end

      format.json do
        candidacies = @election.candidacies.includes(:candidate).order(:id)
        render json: {
          status: @election.status,
          candidacies: candidacies.map { |candidacy| { id: candidacy.id, candidate_name: candidacy.candidate.name } }
        }
      end
    end
  end

  def results
    @election = Election.find(params[:id])
    @candidacies = @election.candidacies.includes(:candidate).order(votes_count: :desc, id: :asc)
    @total_votes = @candidacies.sum(&:votes_count)
  end
end
