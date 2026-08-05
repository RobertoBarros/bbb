require "test_helper"

class VoteTest < ActiveSupport::TestCase
  test "requires a candidacy" do
    vote = Vote.new

    assert_not vote.valid?
    assert vote.errors.of_kind?(:candidacy, :blank)
  end

  test "allows multiple anonymous votes for the same candidacy" do
    candidacy = create_candidacy

    assert_difference -> { candidacy.votes.count }, 2 do
      Vote.create!(candidacy:)
      Vote.create!(candidacy:)
    end
  end

  test "keeps votes isolated between elections" do
    candidate = Candidate.create!(name: "Alice")
    first_election = Election.create!(title: "Board election")
    second_election = Election.create!(title: "Council election")
    first_candidacy = Candidacy.create!(election: first_election, candidate:)
    second_candidacy = Candidacy.create!(election: second_election, candidate:)
    first_vote = Vote.create!(candidacy: first_candidacy)
    Vote.create!(candidacy: second_candidacy)

    assert_equal [ first_vote ], first_election.votes.to_a
    assert_equal 1, second_election.votes.count
  end

  private

    def create_candidacy
      election = Election.create!(title: "Board election")
      candidate = Candidate.create!(name: "Alice")

      Candidacy.create!(election:, candidate:)
    end
end
