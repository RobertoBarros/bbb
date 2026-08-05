require "test_helper"

class CandidacyTest < ActiveSupport::TestCase
  test "prevents the same candidate from joining an election twice" do
    election = Election.create!(title: "Board election")
    candidate = Candidate.create!(name: "Alice")
    Candidacy.create!(election:, candidate:)

    duplicate = Candidacy.new(election:, candidate:)

    assert_not duplicate.valid?
    assert duplicate.errors.of_kind?(:candidate_id, :taken)
  end

  test "allows a candidate to join different elections" do
    candidate = Candidate.create!(name: "Alice")
    first_election = Election.create!(title: "Board election")
    second_election = Election.create!(title: "Council election")

    assert Candidacy.create!(election: first_election, candidate:).persisted?
    assert Candidacy.create!(election: second_election, candidate:).persisted?
  end
end
