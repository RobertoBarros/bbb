class Candidate < ApplicationRecord
  has_many :candidacies
  has_many :elections, through: :candidacies

  validates :name, presence: true
end
