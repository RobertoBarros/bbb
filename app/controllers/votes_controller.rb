class VotesController < ApplicationController
  def create
    RegisterVoteJob.perform_later(params[:election_id], params.dig(:vote, :candidacy_id), Time.current)

    redirect_to root_path, notice: "Voto registrado com sucesso."
  end
end
