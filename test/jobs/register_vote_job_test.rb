require "test_helper"

class RegisterVoteJobTest < ActiveJob::TestCase
  test "registers a vote submitted while the election was open" do
    election = elections(:open)
    candidacy = candidacies(:open_maria)
    submitted_at = election.opened_at + 1.hour

    assert_difference "Vote.count", 1 do
      RegisterVoteJob.perform_now(election.id, candidacy.id, submitted_at)
    end
  end

  test "registers a vote processed after the election closed" do
    election = elections(:closed)
    candidacy = candidacies(:closed_ana)
    submitted_at = election.opened_at + 1.hour

    assert_difference "Vote.count", 1 do
      RegisterVoteJob.perform_now(election.id, candidacy.id, submitted_at)
    end
  end

  test "discards votes submitted outside the election window" do
    election = elections(:closed)
    candidacy = candidacies(:closed_ana)

    [ election.opened_at - 1.second, election.closed_at + 1.second ].each do |submitted_at|
      assert_no_difference "Vote.count" do
        RegisterVoteJob.perform_now(election.id, candidacy.id, submitted_at)
      end
    end
  end

  test "discards missing or mismatched records" do
    assert_no_difference "Vote.count" do
      RegisterVoteJob.perform_now(-1, candidacies(:open_maria).id, Time.current)
      RegisterVoteJob.perform_now(elections(:second_open).id, candidacies(:open_maria).id, Time.current)
    end
  end

  test "is idempotent when the same job runs more than once" do
    election = elections(:open)
    candidacy = candidacies(:open_maria)
    job = RegisterVoteJob.new(election.id, candidacy.id, election.opened_at + 1.hour)

    assert_difference "Vote.count", 1 do
      2.times { job.perform_now }
    end
  end

  test "registers distinct jobs as distinct votes" do
    election = elections(:open)
    candidacy = candidacies(:open_maria)
    submitted_at = election.opened_at + 1.hour

    assert_difference "Vote.count", 2 do
      2.times { RegisterVoteJob.perform_now(election.id, candidacy.id, submitted_at) }
    end
  end
end
