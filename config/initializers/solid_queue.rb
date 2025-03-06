# frozen_string_literal: true

Rails.application.config.after_initialize do
  if defined?(Rails::Server)
    # Schedule the initial check and reschedule itself
    CheckDomainStatusJob.set(wait: 1.minute).perform_later
  end
end
