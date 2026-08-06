class RefreshElectionResultsJob < ApplicationJob
  queue_as :default

  LOCK_KEY = "locks:refresh_election_tallies".freeze
  LOCK_TTL = 1.minute
  RECENTLY_CLOSED_WINDOW = 5.minutes
  RELEASE_LOCK_SCRIPT = <<~LUA.freeze
    if redis.call("get", KEYS[1]) == ARGV[1] then
      return redis.call("del", KEYS[1])
    end
    return 0
  LUA

  def perform
    token = SecureRandom.uuid
    acquired = acquire_lock(token)
    return unless acquired

    elections_to_tally.find_each { |election| refresh(election) }
  ensure
    release_lock(token) if acquired
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

    def acquire_lock(token)
      Sidekiq.redis { |redis| redis.set(LOCK_KEY, token, "NX", "EX", LOCK_TTL.to_i) }
    end

    def release_lock(token)
      Sidekiq.redis { |redis| redis.call("EVAL", RELEASE_LOCK_SCRIPT, 1, LOCK_KEY, token) }
    end
end
