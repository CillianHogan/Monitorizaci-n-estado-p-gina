class ApiEndpoint < ApplicationRecord
  belongs_to :user

  validates :url, presence: true, format: URI::regexp(%w[http https])
  validates :name, presence: true

  enum "status", { pending: 0, up: 1, down: 2, error: 3 }
  enum "http_method", { get: 0, post: 1, put: 2, patch: 3, delete: 4 }, default: :get
  
  after_initialize :set_default_status, if: :new_record?

  def check_status!
    Rails.logger.info("Checking status for API endpoint: #{name} (#{url})")
    response = HTTParty.send(
      http_method,
      url,
      headers: headers,
      format: :json
    )
    
    old_status = status
    new_status = validate_response(response) ? :up : :down
    update!(status: new_status)
    Rails.logger.info("API endpoint #{name} status changed from #{old_status} to #{new_status}")
  rescue StandardError => e
    old_status = status
    update!(status: :error)
    Rails.logger.error("Error checking API endpoint #{name}: #{e.message}")
    notify_error if old_status != :error
  end

  private

  def validate_response(response)
    return response.success? if expected_response.blank?

    response.success? && 
      expected_response.all? { |key, value| response[key] == value }
  end

  def notify_error
    ApiEndpointMailer.status_error_notification(self).deliver_later
  end

  def set_default_status
    self.status = :pending
  end
end