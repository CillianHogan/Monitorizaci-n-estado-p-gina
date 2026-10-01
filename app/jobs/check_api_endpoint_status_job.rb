# frozen_string_literal: true

class CheckApiEndpointStatusJob < ApplicationJob
  queue_as :default

  def perform(endpoint = nil)
    if endpoint
      endpoint.check_status!
    else
      ApiEndpoint.find_each { |ep| self.class.perform_later(ep) }
    end
  rescue StandardError => e
    Rails.logger.error("Error en CheckApiEndpointStatusJob para #{endpoint&.name || 'batch'}: #{e.message}")
  end
end
