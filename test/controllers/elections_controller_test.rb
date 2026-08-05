require "test_helper"

class ElectionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @candidate = Candidate.create!(name: "Maria de Oliveira")
  end

  test "shows candidates and voting form for an open election" do
    election = Election.create!(title: "Votação aberta", status: :open)
    candidacy = Candidacy.create!(election:, candidate: @candidate)

    get election_url(election)

    assert_response :success
    assert_select "h1", election.title
    assert_select "[data-election-status]", "Votação aberta"
    assert_select "form[data-voting-form][action=?][method=post]", election_votes_path(election)
    assert_select "input[type=radio][name='vote[candidacy_id]'][value=?]", candidacy.id.to_s
    assert_select "input[type=submit][value='Confirmar voto']"
  end

  test "shows candidates without voting form for unavailable elections" do
    %i[pending closed].each do |status|
      election = Election.create!(title: "Votação #{status}", status:)
      Candidacy.create!(election:, candidate: @candidate)

      get election_url(election)

      assert_response :success
      assert_select "[data-candidate]", @candidate.name
      assert_select "form[data-voting-form]", count: 0
    end
  end

  test "shows an empty state without candidates" do
    election = Election.create!(title: "Votação vazia", status: :open)

    get election_url(election)

    assert_response :success
    assert_select "[data-empty-state='candidates']", "Nenhum candidato foi adicionado a esta votação."
    assert_select "form[data-voting-form]", count: 0
  end
end
