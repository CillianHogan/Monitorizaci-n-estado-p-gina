class ApiEndpoint < ApplicationRecord
  belongs_to :user
  validates :url, presence: true
  validates :name, presence: true
  validates :expected_response, presence: true

  enum status: { up: 0, down: 1 }
  serialize :expected_response, JSON

  def check_status
    begin
      response = HTTParty.get(url)
      update(status: validate_response?(response) ? :up : :down)
    rescue StandardError => e
      update(status: :down)
      Rails.logger.error("API Endpoint check failed for #{url}: #{e.message}")
    end
  end

  private

  def validate_response?(response)
    response.success? && validate_expected_response?(response)
  end

  def validate_expected_response?(response)
    return true if expected_response.blank?

    expected_response.all? { |key, value| response[key] == value }
  end
end
