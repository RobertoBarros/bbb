require "test_helper"

class VoteTest < ActiveSupport::TestCase
  test "requires a candidacy" do
    vote = Vote.new(submission_id: SecureRandom.uuid, submitted_at: Time.current)

    assert_not vote.valid?
    assert vote.errors.of_kind?(:candidacy, :blank)
  end

  test "requires submission metadata" do
    vote = Vote.new(candidacy: candidacies(:open_maria))

    assert_not vote.valid?
    assert vote.errors.of_kind?(:submission_id, :blank)
    assert vote.errors.of_kind?(:submitted_at, :blank)
  end

  test "allows multiple anonymous votes for the same candidacy" do
    candidacy = candidacies(:open_maria)

    assert_difference -> { candidacy.votes.count }, 2 do
      2.times do
        Vote.create!(candidacy:, submission_id: SecureRandom.uuid, submitted_at: Time.current)
      end
    end
  end

  test "keeps votes isolated between elections" do
    first_election = elections(:open)
    second_election = elections(:second_open)
    first_vote = votes(:open_maria)

    assert_equal [ first_vote ], first_election.votes.to_a
    assert_equal 1, second_election.votes.count
  end

  test "rejects votes for unavailable elections" do
    %i[pending_joao closed_ana].each do |fixture_name|
      candidacy = candidacies(fixture_name)
      vote = Vote.new(candidacy:, submission_id: SecureRandom.uuid, submitted_at: Time.current)

      assert_not vote.valid?
      assert_includes vote.errors[:base], "Esta votação não está aberta."
    end
  end

  test "preserves a vote after its election closes" do
    vote = votes(:open_maria)

    vote.candidacy.election.closed!

    assert_predicate vote, :valid?
  end
end
