class Vote < ApplicationRecord
  belongs_to :candidacy

  validate :election_must_be_open, on: :create

  private

    def election_must_be_open
      return if candidacy.nil? || candidacy.election.open?

      errors.add(:base, "Esta votação não está aberta.")
    end
end
