class Domain < ApplicationRecord
  belongs_to :user
  validates :url, presence: true
  validates :name, presence: true

  enum status: { up: 0, down: 1, pending: 2 }

  def check_status
    begin
      response = HTTParty.get(url)
      update(status: response.success? ? :up : :down)
    rescue StandardError => e
      update(status: :down)
      Rails.logger.error("Domain check failed for #{url}: #{e.message}")
    end
  end
end
