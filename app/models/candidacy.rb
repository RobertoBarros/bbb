class Candidacy < ApplicationRecord
  belongs_to :election
  belongs_to :candidate

  has_many :votes

  validates :candidate_id, uniqueness: { scope: :election_id }
end
