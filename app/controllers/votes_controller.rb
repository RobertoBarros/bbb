class VotesController < ApplicationController
  before_action :set_election

  def create
    if vote_params[:candidacy_id].blank?
      redirect_to @election, alert: "Selecione um candidato para votar."
      return
    end

    candidacy = @election.candidacies.find(vote_params[:candidacy_id])
    vote = candidacy.votes.new

    if vote.save
      redirect_to root_path, notice: "Voto registrado com sucesso."
    else
      redirect_to @election, alert: vote.errors.full_messages.to_sentence
    end
  end

  private

    def set_election
      @election = Election.find(params[:election_id])
    end

    def vote_params
      params.fetch(:vote, ActionController::Parameters.new).permit(:candidacy_id)
    end
end
