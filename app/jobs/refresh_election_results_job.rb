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
      tallied_at = Time.current

      Election.transaction do
        election.candidacies.find_each do |candidacy|
          votes_count = counts.fetch(candidacy.id, 0)
          candidacy.update!(votes_count:) if candidacy.votes_count != votes_count
        end

        election.update!(tallied_at:)
      end
    end
end
