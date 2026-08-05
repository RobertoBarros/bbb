class Election < ApplicationRecord
  has_many :candidacies
  has_many :candidates, through: :candidacies
  has_many :votes, through: :candidacies

  validates :title, presence: true
end
