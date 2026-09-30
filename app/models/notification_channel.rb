# frozen_string_literal: true

class NotificationChannel < ApplicationRecord
  belongs_to :user

  CHANNEL_TYPES = %w[email discord telegram].freeze

  validates :channel_type, presence: true, inclusion: { in: CHANNEL_TYPES }
  validates :destination, presence: true
  validates :name, presence: true

  before_save :ensure_single_default_per_type, if: :is_default?

  scope :by_type, ->(type) { where(channel_type: type.to_s) }
  scope :defaults, -> { where(is_default: true) }

  def self.default_for(type)
    by_type(type).find_by(is_default: true)
  end

  private

  def ensure_single_default_per_type
    NotificationChannel
      .where(user_id: user_id, channel_type: channel_type, is_default: true)
      .where.not(id: id)
      .update_all(is_default: false)
  end
end
