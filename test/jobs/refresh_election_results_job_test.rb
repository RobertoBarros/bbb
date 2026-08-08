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
      assert_equal 0.2, open_election.reload.votes_per_second
      assert_equal 0, zero_vote_candidacy.reload.votes_count
      assert_equal 1, candidacies(:closed_ana).reload.votes_count
      assert_equal 0.2, recent_closed_election.reload.votes_per_second
      assert_equal Time.current, open_election.reload.tallied_at
      assert_equal Time.current, recent_closed_election.reload.tallied_at
      assert_equal 7, pending_candidacy.reload.votes_count
      assert_nil elections(:pending).reload.tallied_at
      assert_equal 8, old_closed_election.candidacies.first.reload.votes_count
      assert_nil old_closed_election.reload.tallied_at
    end
  end

  test "calculates votes per second from the five seconds ending at the last processed vote" do
    travel_to Time.zone.parse("2026-08-05 14:05:00") do
      election = Election.create!(title: "Votação com taxa", status: :open)
      election.update_column(:opened_at, 10.seconds.ago)
      candidate = Candidate.create!(name: "Ana")
      candidacy = Candidacy.create!(election:, candidate:)

      [ 6.seconds.ago, 2.seconds.ago, 1.second.ago, Time.current ].each_with_index do |submitted_at, index|
        Vote.create!(candidacy:, submission_id: "33333333-3333-4333-8333-#{index.to_s.rjust(12, "0")}", submitted_at:)
      end

      RefreshElectionResultsJob.perform_now

      assert_equal 0.6, election.reload.votes_per_second
    end
  end

  test "calculates votes per second when the last processed vote is older than five seconds" do
    travel_to Time.zone.parse("2026-08-05 14:05:00") do
      election = Election.create!(title: "Votação com atraso", status: :open)
      election.update_column(:opened_at, 2.minutes.ago)
      candidate = Candidate.create!(name: "Ana")
      candidacy = Candidacy.create!(election:, candidate:)

      [ 67.seconds.ago, 61.seconds.ago, 60.seconds.ago ].each_with_index do |submitted_at, index|
        Vote.create!(candidacy:, submission_id: "55555555-5555-4555-8555-#{index.to_s.rjust(12, "0")}", submitted_at:)
      end

      RefreshElectionResultsJob.perform_now

      assert_equal 0.4, election.reload.votes_per_second
    end
  end

  test "uses a five-second window for votes submitted at the same time" do
    travel_to Time.zone.parse("2026-08-05 14:05:00") do
      election = Election.create!(title: "Votação simultânea", status: :open)
      candidate = Candidate.create!(name: "Ana")
      candidacy = Candidacy.create!(election:, candidate:)

      3.times do |index|
        Vote.create!(candidacy:, submission_id: "44444444-4444-4444-8444-#{index.to_s.rjust(12, "0")}", submitted_at: Time.current)
      end

      RefreshElectionResultsJob.perform_now

      assert_equal 0.6, election.reload.votes_per_second
    end
  end

  test "stores zero votes per second when an open election has no votes" do
    election = Election.create!(title: "Votação sem votos", status: :open)

    RefreshElectionResultsJob.perform_now

    assert_equal 0, election.reload.votes_per_second
  end
end
