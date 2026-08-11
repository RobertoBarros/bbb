require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @open_election = Election.create!(title: "Votação aberta", status: :open)
    @closed_election = Election.create!(title: "Votação encerrada", status: :closed)
    @pending_election = Election.create!(title: "Votação pendente")
    @open_candidate = Candidate.create!(name: "Candidata Aberta")
    @closed_candidate = Candidate.create!(name: "Candidato Encerrado")
    @pending_candidate = Candidate.create!(name: "Candidata Pendente")
    Candidacy.create!(election: @open_election, candidate: @open_candidate)
    Candidacy.create!(election: @closed_election, candidate: @closed_candidate)
    Candidacy.create!(election: @pending_election, candidate: @pending_candidate)
  end

  test "shows the open election and closed election results" do
    get root_url

    assert_response :success
    assert_select "[data-election='open']", count: 1
    assert_select "[data-election='open'] [data-candidate]", count: 1
    assert_select "[data-election='open'] a[href=?]", election_path(@open_election)
    assert_select "[data-election='closed'] [data-candidate]"
    assert_select "[data-election='closed'] a[href=?]", results_election_path(@closed_election)
  end

  test "shows empty states without open or closed elections" do
    Election.update_all(status: :pending)

    get root_url

    assert_response :success
    assert_select "[data-empty-state='open']", count: 1
    assert_select "[data-empty-state='closed']", count: 1
  end
end
