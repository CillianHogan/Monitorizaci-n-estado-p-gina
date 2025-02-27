# frozen_string_literal: true

class Domain < ApplicationRecord
  belongs_to :user
  has_many :status_histories, dependent: :destroy, class_name: 'DomainStatusHistory'

  validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp, message: 'must be a valid URL' }
  validates :name, presence: true

  enum :status, { pending: 0, up: 1, down: 2, error: 3 }, prefix: true

  after_save :create_status_history, if: :saved_change_to_status?

  def check_status!
    response = HTTParty.head(url)
    update(status: response.success? ? :up : :down)
  rescue StandardError => e
    Rails.logger.error("Domain check failed for #{url}: #{e.message}")
    update(status: :error)
    notify_error
  end

  private

  def notify_error
    DomainMailer.status_error_notification(self).deliver_now
  end

  def create_status_history
    status_histories.create!(status: status, recorded_at: Time.current)
  end
end
