class RegisterVoteJob < ApplicationJob
  queue_as :votes

  discard_on ActiveRecord::RecordInvalid
  discard_on ActiveRecord::RecordNotFound

  def perform(election_id, candidacy_id, submitted_at)
    election = Election.find(election_id)
    candidacy = election.candidacies.find(candidacy_id)

    Vote.register!(candidacy:, submission_id: job_id, submitted_at:)
  end
end
