class PagesController < ApplicationController
  def home
    @open_election = Election.open.includes(:candidates).order(id: :desc).first
    @closed_elections = Election.closed.includes(:candidates).order(id: :desc)
  end
end
