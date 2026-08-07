class RefreshElectionResultsJob < ApplicationJob
  queue_as :results

  RECENTLY_CLOSED_WINDOW = 5.minutes

  def perform
    elections_to_tally.find_each { |election| refresh(election) }
  end

  private

    def elections_to_tally
      Election.open.or(Election.closed.where(closed_at: RECENTLY_CLOSED_WINDOW.ago..))
    end

    def refresh(election)
      counts = election.votes.group(:candidacy_id).count
      total_votes = counts.values.sum
      first_submitted_at = election.votes.minimum(:submitted_at)
      last_submitted_at = election.votes.maximum(:submitted_at)
      votes_per_second = if total_votes.zero?
        0
      else
        total_votes.fdiv([ last_submitted_at - first_submitted_at, 1 ].max)
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
