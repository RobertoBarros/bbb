class Election < ApplicationRecord
  has_many :candidacies
  has_many :candidates, through: :candidacies
  has_many :votes, through: :candidacies

  enum :status, { pending: 0, open: 1, closed: 2 }, default: :pending

  validates :title, presence: true
end
