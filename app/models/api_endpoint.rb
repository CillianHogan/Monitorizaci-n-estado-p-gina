# frozen_string_literal: true

class ApiEndpoint < ApplicationRecord
  belongs_to :user
  validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp, message: 'must be a valid URL' }
  validates :name, presence: true
  validates :expected_response, presence: false

  enum :status, { pending: 0, up: 1, down: 2, error: 3 }, prefix: true
  enum :http_method, { get: 0, post: 1, put: 2, patch: 3, remove: 4 }, default: :get

  after_update_commit :notify_error, if: -> { saved_change_to_status?(to: :error) }

  def check_status!
    response = HTTParty.get(url)
    update(status: validate_response?(response) ? :up : :down)
  rescue StandardError => e
    Rails.logger.error("API Endpoint check failed for #{url}: #{e.message}")
    update(status: :error)
  end

  private

  def notify_error
    ApiEndpointMailer.status_error_notification(self).deliver_now
  end

  def validate_response?(response)
    response.success? && validate_expected_response?(response)
  end

  def validate_expected_response?(response)
    return true if expected_response.blank?

    expected_response.all? { |key, value| response[key] == value }
  end
end
