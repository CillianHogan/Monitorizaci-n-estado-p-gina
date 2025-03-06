# frozen_string_literal: true

class CheckDomainStatusJob < ApplicationJob
  queue_as :default

  def perform
    Domain.find_each do |domain|
      domain.check_status!
    rescue StandardError => e
      Rails.logger.error("Error checking domain #{domain.id}: #{e.message}")
    end

    # Reschedule the job to run again in 5 minutes
    self.class.set(wait: 1.minute).perform_later
  rescue StandardError => e
    Rails.logger.error("Error in CheckDomainStatusJob: #{e.message}")
  end
end
