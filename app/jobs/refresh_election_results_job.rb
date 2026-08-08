class RefreshElectionResultsJob < ApplicationJob
  queue_as :results

  RECENTLY_CLOSED_WINDOW = 5.minutes
  VOTES_PER_SECOND_WINDOW = 5.seconds

  def perform
    elections_to_tally.find_each { |election| refresh(election) }
  end

  private

    def elections_to_tally
      Election.open.or(Election.closed.where(closed_at: RECENTLY_CLOSED_WINDOW.ago..))
    end

    def refresh(election)
      counts = election.votes.group(:candidacy_id).count
      last_submitted_at = election.votes.maximum(:submitted_at)
      votes_per_second = if last_submitted_at
        election.votes.where(submitted_at: (last_submitted_at - VOTES_PER_SECOND_WINDOW)..last_submitted_at).count.fdiv(VOTES_PER_SECOND_WINDOW)
      else
        0
      end
      tallied_at = Time.current

      Election.transaction do
        election.candidacies.find_each do |candidacy|
          votes_count = counts.fetch(candidacy.id, 0)
          candidacy.update!(votes_count:) if candidacy.votes_count != votes_count
        end

        election.update!(tallied_at:, votes_per_second:)
      end
    end
end
