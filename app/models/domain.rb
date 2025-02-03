class Domain < ApplicationRecord
  belongs_to :user
  validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp, message: "must be a valid URL" }
  validates :name, presence: true

  enum :status, { pending: 0, up: 1, down: 2, error: 3 }, prefix: true

  def check_status!
    begin
      response = HTTParty.head(url)
      update(status: response.success? ? :up : :down)
    rescue StandardError => e
      update(status: :error)
      Rails.logger.error("Domain check failed for #{url}: #{e.message}")
      DomainMailer.status_error_notification(self).deliver_now
    end
  end
end
