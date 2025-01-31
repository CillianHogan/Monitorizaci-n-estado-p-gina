class Domain < ApplicationRecord
  belongs_to :user

  validates :url, presence: true, format: URI.regexp(%w[http https])
  validates :name, presence: true

  enum :status, { pending: 0, up: 1, down: 2, error: 3 }

  after_initialize :set_default_status, if: :new_record?

  def check_status!
    Rails.logger.info("Checking status for domain: #{name} (#{url})")
    response = HTTParty.head(url)

    old_status = status
    new_status = response.success? ? :up : :down
    update!(status: new_status)
    Rails.logger.info("Domain #{name} status changed from #{old_status} to #{new_status}")
  rescue StandardError => e
    Rails.logger.error("Error checking domain #{name}: #{e.message}")
    if status != :error
      update!(status: :error)
      notify_error
    end
  end

  private

  def notify_error
    DomainMailer.status_error_notification(self).deliver_now
  end

  def set_default_status
    self.status = :pending
  end
end