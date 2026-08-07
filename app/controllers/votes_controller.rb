class VotesController < ApplicationController
  skip_forgery_protection only: :create, if: -> { request.format.json? }

  rate_limit to: 5, within: 1.minute, only: :create,
    unless: -> { ENV["LOAD_TEST_MODE"] == "true" }

  def create
    RegisterVoteJob.perform_later(params[:election_id], params.dig(:vote, :candidacy_id), Time.current)

    respond_to do |format|
      format.html do
        redirect_to root_path, notice: "Voto registrado com sucesso."
      end

      format.json do
        render json: { message: "Voto registrado com sucesso." }, status: :accepted
      end
    end
  end
end
