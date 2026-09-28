require "net/http"
require "uri"
require "json"

class DiscordNotificationJob < ApplicationJob
  queue_as :default

  def perform(webhook_url, payload)
    return if webhook_url.blank?

    uri = URI.parse(webhook_url.to_s.strip)
    return unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")
    http.open_timeout = 5
    http.read_timeout = 5

    path = uri.request_uri.presence || "/"
    request = Net::HTTP::Post.new(path, {
      "Content-Type" => "application/json",
      "User-Agent" => "DomainMonitor/1.0"
    })
    request.body = payload.to_json

    response = http.request(request)
    unless response.is_a?(Net::HTTPSuccess) || response.code.to_i == 204
      Rails.logger.error "[DiscordNotificationJob] Error al enviar a Discord: #{response.code} #{response.body}"
    end
  rescue StandardError => e
    Rails.logger.error "[DiscordNotificationJob] Excepcion enviando alerta a Discord: #{e.message}"
  end
end
