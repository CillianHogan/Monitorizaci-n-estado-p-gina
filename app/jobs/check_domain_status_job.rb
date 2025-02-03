class CheckDomainStatusJob < ApplicationJob
  queue_as :default

  def perform
    Domain.find_each do |domain|
      domain.check_status!
    end

    # Reschedule the job to run again in 5 minutes
    self.class.set(wait: 5.minutes).perform_later
  rescue StandardError => e
    Rails.logger.error("Error checking domain #{domain_id}: #{e.message}")
  end
end
