require "test_helper"

class CandidacyTest < ActiveSupport::TestCase
  test "prevents the same candidate from joining an election twice" do
    duplicate = Candidacy.new(election: elections(:open), candidate: candidates(:maria))

    assert_not duplicate.valid?
    assert duplicate.errors.of_kind?(:candidate_id, :taken)
  end

  test "allows a candidate to join different elections" do
    existing_candidacy = candidacies(:open_maria)
    new_candidacy = Candidacy.create!(election: elections(:closed), candidate: candidates(:maria))

    assert_predicate existing_candidacy, :persisted?
    assert_predicate new_candidacy, :persisted?
  end
end
