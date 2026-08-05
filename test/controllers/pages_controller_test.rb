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
    assert_select "h1", "Vote de forma simples e anônima."
    assert_select "[data-election='open'] [data-election-title]", @open_election.title
    assert_select "[data-election='open'] [data-candidate]", @open_candidate.name
    assert_select "[data-election='open'] a[href=?]", election_path(@open_election), text: "Votar agora"
    assert_select "[data-election='closed'] [data-election-title]", @closed_election.title
    assert_select "[data-election='closed'] [data-candidate]", @closed_candidate.name
    assert_select "[data-election='closed'] a[href='#']", "Ver resultados"
    assert_select "[data-election-title]", text: @pending_election.title, count: 0
    assert_select "[data-candidate]", text: @pending_candidate.name, count: 0
  end

  test "shows empty states without open or closed elections" do
    Election.update_all(status: :pending)

    get root_url

    assert_response :success
    assert_select "[data-empty-state='open']", "Nenhuma votação aberta no momento."
    assert_select "[data-empty-state='closed']", "Nenhum resultado disponível."
  end
end
