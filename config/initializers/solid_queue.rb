Rails.application.config.after_initialize do
  if defined?(Rails::Server)
    # Schedule the initial check and reschedule itself
    CheckDomainStatusJob.set(wait: 5.minutes).perform_later
  end
end