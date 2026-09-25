# frozen_string_literal: true

class CheckDomainStatusJob < ApplicationJob
  queue_as :default

  def perform(domain = nil, attempt: 1)
    if domain
      verify_single_domain(domain, attempt: attempt)
    else
      Domain.find_each { |d1| self.class.perform_later(d1, attempt: 1) }
    end
  end

  private

  def verify_single_domain(domain, attempt:)
    if attempt == 1
      success = domain.check_status!(record_down: false)
      unless success
        Rails.logger.warn("Fallo transitorio en #{domain.url}. Reintentando en 15 segundos...")
        self.class.set(wait: 15.seconds).perform_later(domain, attempt: 2)
      end
    else
      success = domain.check_status!(record_down: true)
      if success
        Rails.logger.info("Recuperado #{domain.url} en reintento.")
      else
        Rails.logger.error("Confirmado fallo en #{domain.url} tras reintento.")
      end
    end
  rescue StandardError => e
    Rails.logger.error("Error inesperado en verificacion de #{domain&.url}: #{e.message}")
  end
end
