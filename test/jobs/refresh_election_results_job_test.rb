require "test_helper"

class RefreshElectionResultsJobTest < ActiveJob::TestCase
  test "uses the results queue" do
    assert_equal "results", RefreshElectionResultsJob.queue_name
  end

  test "updates open and recently closed elections" do
    travel_to Time.zone.parse("2026-08-05 14:05:00") do
      open_election = elections(:open)
      zero_vote_candidacy = Candidacy.create!(election: open_election, candidate: candidates(:joao))
      recent_closed_election = elections(:closed)
      recent_closed_election.update!(opened_at: 1.hour.ago, closed_at: 1.minute.ago)
      Vote.create!(
        candidacy: candidacies(:closed_ana),
        submission_id: "33333333-3333-4333-8333-333333333333",
        submitted_at: 30.minutes.ago
      )
      pending_candidacy = candidacies(:pending_joao)
      pending_candidacy.update_column(:votes_count, 7)
      old_closed_election = elections(:second_open)
      old_closed_election.update_columns(
        status: Election.statuses.fetch("closed"),
        opened_at: 2.hours.ago,
        closed_at: 6.minutes.ago
      )
      old_closed_election.candidacies.first.update_column(:votes_count, 8)

      RefreshElectionResultsJob.perform_now

      assert_equal 1, candidacies(:open_maria).reload.votes_count
      assert_equal 0, zero_vote_candidacy.reload.votes_count
      assert_equal 1, candidacies(:closed_ana).reload.votes_count
      assert_equal Time.current, open_election.reload.tallied_at
      assert_equal Time.current, recent_closed_election.reload.tallied_at
      assert_equal 7, pending_candidacy.reload.votes_count
      assert_nil elections(:pending).reload.tallied_at
      assert_equal 8, old_closed_election.candidacies.first.reload.votes_count
      assert_nil old_closed_election.reload.tallied_at
    end
  end
end
