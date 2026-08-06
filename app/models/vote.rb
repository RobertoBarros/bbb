class Vote < ApplicationRecord
  belongs_to :candidacy

  validates :submission_id, :submitted_at, presence: true
  validate :submission_must_be_within_election_window

  def self.register!(candidacy:, submission_id:, submitted_at:)
    create_or_find_by!(submission_id:) do |vote|
      vote.candidacy = candidacy
      vote.submitted_at = submitted_at
    end
  end

  private

    def submission_must_be_within_election_window
      return if candidacy.nil? || submitted_at.nil?

      election = candidacy.election
      within_window = election.opened_at.present? &&
        submitted_at >= election.opened_at &&
        (election.closed_at.nil? || submitted_at <= election.closed_at)
      return if within_window

      errors.add(:base, "Esta votação não está aberta.")
    end
end
