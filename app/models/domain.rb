class Domain < ApplicationRecord
  belongs_to :user
  validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp, message: "must be a valid URL" }
  validates :name, presence: true

  enum :status, { pending: 0, up: 1, down: 2, error: 3 }, prefix: true

  after_update_commit :notify_error, if: -> { saved_change_to_status? && status_error? }

  def check_status!
    begin
      response = HTTParty.head(url)
      update(status: response.success? ? :up : :down)
    rescue StandardError => e
      update(status: :error)
      Rails.logger.error("Domain check failed for #{url}: #{e.message}")
    end
  end

  private

  def notify_error
    DomainMailer.status_error_notification(self).deliver_now
  end
end
