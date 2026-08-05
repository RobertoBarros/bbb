require "test_helper"

class VotesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @candidate = Candidate.create!(name: "Maria de Oliveira")
    @open_election = Election.create!(title: "Votação aberta", status: :open)
    @candidacy = Candidacy.create!(election: @open_election, candidate: @candidate)
  end

  test "creates an anonymous vote and redirects to home" do
    assert_difference "Vote.count", 1 do
      post election_votes_url(@open_election), params: { vote: { candidacy_id: @candidacy.id } }
    end

    assert_redirected_to root_url
    assert_equal "Voto registrado com sucesso.", flash[:notice]

    follow_redirect!
    assert_select "[data-flash='notice']", "Voto registrado com sucesso."
  end

  test "does not create a vote without a selected candidate" do
    assert_no_difference "Vote.count" do
      post election_votes_url(@open_election), params: { vote: {} }
    end

    assert_redirected_to election_url(@open_election)
    assert_equal "Selecione um candidato para votar.", flash[:alert]
  end

  test "does not create votes for unavailable elections" do
    %i[pending closed].each do |status|
      election = Election.create!(title: "Votação #{status}", status:)
      candidacy = Candidacy.create!(election:, candidate: @candidate)

      assert_no_difference "Vote.count" do
        post election_votes_url(election), params: { vote: { candidacy_id: candidacy.id } }
      end

      assert_redirected_to election_url(election)
      assert_equal "Esta votação não está aberta.", flash[:alert]
    end
  end

  test "rejects a candidacy from another election" do
    other_election = Election.create!(title: "Outra votação", status: :open)

    assert_no_difference "Vote.count" do
      post election_votes_url(other_election), params: { vote: { candidacy_id: @candidacy.id } }
    end

    assert_response :not_found
  end

  test "allows repeated anonymous votes" do
    assert_difference "Vote.count", 2 do
      2.times do
        post election_votes_url(@open_election), params: { vote: { candidacy_id: @candidacy.id } }
      end
    end
  end
end
