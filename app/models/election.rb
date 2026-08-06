class Election < ApplicationRecord
  STATUS_TRANSITIONS = {
    "pending" => "open",
    "open" => "closed"
  }.freeze

  has_many :candidacies
  has_many :candidates, through: :candidacies
  has_many :votes, through: :candidacies

  enum :status, { pending: 0, open: 1, closed: 2 }, default: :pending

  validates :title, presence: true
  validate :status_transition_must_be_forward, on: :update
  validate :status_timestamps_must_match_status

  before_validation :set_status_timestamps, if: :will_save_change_to_status?

  private

    def set_status_timestamps
      now = Time.current

      case status
      when "pending"
        self.opened_at = nil
        self.closed_at = nil
      when "open"
        self.opened_at = now
        self.closed_at = nil
      when "closed"
        self.opened_at ||= now
        self.closed_at = now
      end
    end

    def status_transition_must_be_forward
      return unless will_save_change_to_status?

      previous_status = status_was
      return if STATUS_TRANSITIONS[previous_status] == status

      errors.add(:status, "não pode mudar de #{previous_status} para #{status}")
    end

    def status_timestamps_must_match_status
      errors.add(:opened_at, :blank) if !pending? && opened_at.blank?
      errors.add(:closed_at, :blank) if closed? && closed_at.blank?
      errors.add(:closed_at, :present) if !closed? && closed_at.present?
    end
end
