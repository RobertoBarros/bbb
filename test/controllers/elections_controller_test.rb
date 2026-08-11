require "test_helper"

class ElectionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @candidate = Candidate.create!(name: "Maria de Oliveira")
  end

  test "lists all elections as JSON" do
    get elections_url, as: :json

    assert_response :success
    assert_equal(
      {
        "elections" => Election.order(:id).map do |election|
          { "id" => election.id, "title" => election.title, "status" => election.status }
        end
      },
      response.parsed_body
    )
  end

  test "shows candidates and voting form for an open election" do
    election = Election.create!(title: "Votação aberta", status: :open)
    candidacy = Candidacy.create!(election:, candidate: @candidate)

    get election_url(election)

    assert_response :success
    assert_select "h1", count: 1
    assert_select "[data-election-status]", count: 1
    assert_select "form[data-voting-form][action=?][method=post]", election_votes_path(election)
    assert_select "input[type=radio][name='vote[candidacy_id]'][value=?]", candidacy.id.to_s
    assert_select "input[type=submit]", count: 1
  end

  test "returns an election status and candidacy IDs as JSON" do
    election = Election.create!(title: "Votação aberta", status: :open)
    first_candidacy = Candidacy.create!(election:, candidate: @candidate)
    second_candidacy = Candidacy.create!(election:, candidate: Candidate.create!(name: "João da Silva"))

    get election_url(election), as: :json

    assert_response :success
    assert_equal(
      {
        "status" => "open",
        "candidacies" => [
          { "id" => first_candidacy.id, "candidate_name" => @candidate.name },
          { "id" => second_candidacy.id, "candidate_name" => "João da Silva" }
        ]
      },
      response.parsed_body
    )
  end

  test "shows candidates without voting form for unavailable elections" do
    %i[pending closed].each do |status|
      election = Election.create!(title: "Votação #{status}", status:)
      Candidacy.create!(election:, candidate: @candidate)

      get election_url(election)

      assert_response :success
      assert_select "[data-candidate]", count: 1
      assert_select "form[data-voting-form]", count: 0
    end
  end

  test "shows an empty state without candidates" do
    election = Election.create!(title: "Votação vazia", status: :open)

    get election_url(election)

    assert_response :success
    assert_select "[data-empty-state='candidates']", count: 1
    assert_select "form[data-voting-form]", count: 0
  end

  test "shows a ranked result dashboard with tally details" do
    election = Election.create!(title: "Votação em apuração", status: :open)
    first_candidate = Candidate.create!(name: "Ana Ribeiro")
    second_candidate = Candidate.create!(name: "Bruno Costa")
    Candidacy.create!(election:, candidate: first_candidate, votes_count: 3)
    Candidacy.create!(election:, candidate: second_candidate, votes_count: 1)
    election.update!(tallied_at: Time.zone.parse("2026-08-06 14:30:00"), votes_per_second: 1.25)

    get results_election_url(election)

    assert_response :success
    assert_select "[data-controller='results-refresh']", count: 1
    assert_select "[data-results-refresh-target='status'][hidden]", text: "Atualizando resultados…", count: 1
    assert_select "h1", count: 1
    assert_select "[data-election-status]", count: 1
    assert_select "[data-total-votes]", count: 1
    assert_select "[data-votes-per-second]", count: 1
    assert_select "[data-tallied-at]", count: 1
    assert_select "[data-result-candidate]", count: 2
    assert_select "[data-result-candidate]:nth-child(1) [data-candidate-rank]", count: 1
    assert_select "[data-result-candidate]:nth-child(1) [data-candidate-name]", count: 1
    assert_select "[data-result-candidate]:nth-child(1) [data-candidate-votes]", count: 1
    assert_select "[data-result-candidate]:nth-child(2) [data-candidate-rank]", count: 1
    assert_select "[data-result-candidate]:nth-child(2) [data-candidate-name]", count: 1
    assert_select "[data-result-candidate]:nth-child(2) [data-candidate-votes]", count: 1
  end

  test "returns ranked election results as JSON" do
    election = Election.create!(title: "Votação em apuração", status: :open)
    first_candidate = Candidate.create!(name: "Ana Ribeiro")
    second_candidate = Candidate.create!(name: "Bruno Costa")
    first_candidacy = Candidacy.create!(election:, candidate: first_candidate, votes_count: 3)
    second_candidacy = Candidacy.create!(election:, candidate: second_candidate, votes_count: 1)
    tallied_at = Time.zone.parse("2026-08-06 14:30:00")
    election.update!(tallied_at:, votes_per_second: 1.25)

    get results_election_url(election), as: :json

    assert_response :success
    assert_equal(
      {
        "election" => {
          "id" => election.id,
          "title" => election.title,
          "status" => "open",
          "tallied_at" => tallied_at.as_json,
          "votes_per_second" => 1.25
        },
        "total_votes" => 4,
        "candidacies" => [
          { "id" => first_candidacy.id, "candidate_name" => first_candidate.name, "votes_count" => 3, "percentage" => 75.0 },
          { "id" => second_candidacy.id, "candidate_name" => second_candidate.name, "votes_count" => 1, "percentage" => 25.0 }
        ]
      },
      response.parsed_body
    )
  end

  test "shows zero results and pending tally for elections in every status" do
    %i[pending open closed].each do |status|
      election = Election.create!(title: "Votação #{status}", status:)
      Candidacy.create!(election:, candidate: @candidate)

      get results_election_url(election)

      assert_response :success
      assert_select "[data-total-votes]", count: 1
      assert_select "[data-votes-per-second]", count: 1
      assert_select "[data-tally-pending]", count: 1
      assert_select "[data-candidate-votes]", count: 1
    end
  end

  test "shows an empty result state without candidates" do
    election = Election.create!(title: "Votação sem candidatos")

    get results_election_url(election)

    assert_response :success
    assert_select "[data-empty-state='results']", count: 1
  end
end
