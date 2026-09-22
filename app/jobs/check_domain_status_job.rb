# frozen_string_literal: true

class CheckDomainStatusJob < ApplicationJob
  queue_as :default

  # Si se le pasa un dominio, comprueba solo ese (reintento a los 15s).
  # Si no se le pasa nada, ejecuta el barrido general de todos los dominios.
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
  rescue StandardError => e
    if attempt == 1
      Rails.logger.warn("Fallo transitorio en #{domain.url}. Reintentando en 15 segundos...")
      self.class.set(wait: 15.seconds).perform_later(domain, attempt: 2)
    else
      Rails.logger.error("Confirmado fallo en #{domain.url} tras reintento: #{e.message}")
    end
  end
end
