require "net/http"
require "uri"
require "json"

class TelegramNotificationJob < ApplicationJob
  queue_as :default

  def perform(bot_token, chat_id, text)
    return if bot_token.blank? || chat_id.blank? || text.blank?

    uri = URI.parse("https://api.telegram.org/bot#{bot_token.to_s.strip}/sendMessage")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 5
    http.read_timeout = 5

    request = Net::HTTP::Post.new(uri.request_uri, {
      "Content-Type" => "application/json",
      "User-Agent" => "DomainMonitor/1.0"
    })
    request.body = {
      chat_id: chat_id.to_s.strip,
      text: text,
      parse_mode: "Markdown"
    }.to_json

    response = http.request(request)
    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error "[TelegramNotificationJob] Error al enviar a Telegram: #{response.code} #{response.body}"
    end
  rescue StandardError => e
    Rails.logger.error "[TelegramNotificationJob] Excepcion enviando alerta a Telegram: #{e.message}"
  end
end
