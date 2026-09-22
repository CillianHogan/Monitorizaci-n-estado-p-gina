# frozen_string_literal: true

class CheckDomainStatusJob < ApplicationJob
  queue_as :default

  def perform(domain = nil, attempt: 1)
    if domain
      verify_single_domain(domain, attempt: attempt)
    else
      Domain.find_each { |d| self.class.perform_later(d, attempt: 1) }
      self.class.set(wait: 5.minutes).perform_later
    end
  end

  private

  def verify_single_domain(domain, attempt:)
    domain.check_status!
    update_domain_ssl(domain)
  rescue StandardError => e
    if attempt == 1
      Rails.logger.warn("Fallo transitorio en #{domain.url}. Reintentando en 15 segundos...")
      self.class.set(wait: 15.seconds).perform_later(domain, attempt: 2)
    else
      Rails.logger.error("Confirmado fallo en #{domain.url} tras reintento: #{e.message}")
    end
  end

  def update_domain_ssl(domain)
    ssl_info = domain.check_ssl
    return unless ssl_info

    domain.update_columns(
      ssl_valid: ssl_info[:valid] || false,
      ssl_issuer: ssl_info[:issuer],
      ssl_expires_at: ssl_info[:expires_at],
      ssl_days_remaining: ssl_info[:days_remaining]
    )

    check_ssl_notifications(domain)
  rescue StandardError => e
    Rails.logger.warn("No se pudo actualizar la información SSL para #{domain.url}: #{e.message}")
  end

  def check_ssl_notifications(domain)
    return unless domain.ssl_valid? && domain.ssl_days_remaining.present?

    # Dispara alerta preventiva solo en umbrales clave
    if [30, 15, 7].include?(domain.ssl_days_remaining)
      DomainMailer.ssl_expiration_warning_notification(domain).deliver_now
    end
  end
end
