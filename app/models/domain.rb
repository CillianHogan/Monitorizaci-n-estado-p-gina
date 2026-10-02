# frozen_string_literal: true

require "securerandom"
require "socket"
require "openssl"
require "httparty"

class Domain < ApplicationRecord

def target_email
  return notify_email_address if respond_to?(:notify_email_address) && notify_email_address.present?
  return user.notification_channels.default_for(:email)&.destination if user.present? && user.notification_channels.default_for(:email).present?
  user&.email
end

def target_discord_webhook
  return discord_webhook_url if discord_webhook_url.present?
  user&.notification_channels&.default_for(:discord)&.destination
end

def target_telegram_chat_id
  return telegram_chat_id if telegram_chat_id.present?
  user&.notification_channels&.default_for(:telegram)&.destination
end

  belongs_to :user
  has_many :status_histories, dependent: :destroy, class_name: "DomainStatusHistory"
  has_one :latest_status_history, -> { order(recorded_at: :desc) }, class_name: "DomainStatusHistory"

  attr_accessor :current_response_time_ms, :current_http_code

  before_validation :normalize_url
  before_validation :generate_public_token, on: :create

  validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp, message: "must be a valid URL" }
  validates :name, presence: true
  validates :public_token, presence: true, uniqueness: true

  enum :status, { pending: 0, up: 1, down: 2, error: 3 }, prefix: true

  after_create :check_initial_status
  after_save :create_status_history
  after_update_commit :notify_status_change, if: -> { saved_change_to_status? }

  def check_status!(record_down: true)
    clean_url = url.to_s.strip
    http_status = :down
    response_time = nil

    begin
      headers = {
        "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36",
        "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
        "Accept-Language" => "es-ES,es;q=0.9,en;q=0.8",
        "Cache-Control" => "no-cache",
        "Pragma" => "no-cache"
      }

      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      response = HTTParty.get(clean_url, timeout: 10, follow_redirects: true, headers: headers)
      end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      response_time = ((end_time - start_time) * 1000).to_i
      @last_http_code = response.code

      is_valid_code = (200..399).cover?(@last_http_code)
      keyword_matches = expected_keyword.blank? || response.body.to_s.include?(expected_keyword.to_s.strip)

      http_status = (is_valid_code && keyword_matches) ? :up : :down
    rescue StandardError => e
      Rails.logger.warn("HTTP check failed for #{clean_url}: #{e.message}")
      http_status = :down
    end

    # Si ha fallado y estamos en intento transitorio, no guardamos caida en BD todavia
    return false if http_status == :down && !record_down

    ssl_data = check_ssl

    self.current_response_time_ms = response_time
    self.current_http_code = @last_http_code

    update(
      status: http_status,
      ssl_valid: ssl_data[:valid] || false,
      ssl_issuer: ssl_data[:issuer],
      ssl_expires_at: ssl_data[:expires_at],
      ssl_days_remaining: ssl_data[:days_remaining]
    )
    check_latency_alert!(response_time)
    check_ssl_expiration_alert!

    http_status == :up
  end


def check_latency_alert!(latency_ms)
    return unless latency_alert_enabled? && status_up? && latency_ms.present?
    threshold = max_latency_threshold_ms.presence || 2000
    return if latency_ms <= threshold

    # Cooldown estricto de 4 horas por dominio
    return if latency_alert_sent_at.present? && latency_alert_sent_at > 4.hours.ago

    DomainMailer.high_latency_notification(self, latency_ms).deliver_later
    update_column(:latency_alert_sent_at, Time.current)
  rescue StandardError => e
    Rails.logger.error("Error sending high latency notification for #{name}: #{e.message}")
  end

  def check_ssl_expiration_alert!
    return unless ssl_valid? && ssl_days_remaining.present?
    return if ssl_alert_sent_at == Date.current

    should_notify = case ssl_days_remaining
                    when 30, 15
                      true
                    when 1..5
                      true
                    else
                      false
                    end

    if should_notify
      DomainMailer.ssl_expiration_warning_notification(self).deliver_later if notify_email?
    send_discord_ssl_alert(ssl_days_remaining)
    send_telegram_ssl_alert(ssl_days_remaining)
    update_column(:ssl_alert_sent_at, Date.current)
    end
  end

  def check_ssl
    clean_url = url.to_s.strip
    uri = URI.parse(clean_url)
    host = uri.host || clean_url

    tcp_client = Socket.tcp(host, 443, connect_timeout: 5)
    ssl_context = OpenSSL::SSL::SSLContext.new
    ssl_client = OpenSSL::SSL::SSLSocket.new(tcp_client, ssl_context)
    ssl_client.hostname = host
    ssl_client.connect

    cert = ssl_client.peer_cert
    ssl_client.close

    return { valid: false, error: "Certificado no encontrado" } unless cert

    days_remaining = ((cert.not_after - Time.current) / 1.day).to_i
    issuer = cert.issuer.to_a.find { |field| field[0] == "O" }&.at(1) || "Desconocido"

    {
      valid: days_remaining.positive?,
      expires_at: cert.not_after,
      days_remaining: days_remaining,
      issuer: issuer
    }
  rescue StandardError => e
    Rails.logger.warn("SSL check failed for #{clean_url}: #{e.message}")
    { valid: false, error: e.message }
  end

  
  def last_response_time_ms
    status_histories.order(recorded_at: :desc).first&.response_time_ms
  end

  def average_response_time_ms(since = 24.hours.ago)
    status_histories.where("recorded_at >= ?", since).average(:response_time_ms)&.round
  end
def send_discord_alert(type)
  return unless notify_discord? && target_discord_webhook.present?

  color = type == :up ? 3066993 : 15158332 # Verde o Rojo
  title = type == :up ? "🟢 Dominio Recuperado: #{name}" : "🔴 Dominio Caído: #{name}"
  desc  = type == :up ? "El dominio **#{url}** vuelve a responder con normalidad." : "El dominio **#{url}** no responde o devuelve un código de error."

  payload = {
    embeds: [
      {
        title: title,
        description: desc,
        color: color,
        timestamp: Time.current.iso8601,
        fields: [
          { name: "Estado actual", value: status.to_s.upcase, inline: true },
          { name: "URL", value: url, inline: true }
        ]
      }
    ]
  }

  DiscordNotificationJob.perform_later(target_discord_webhook, payload)
rescue StandardError => e
  Rails.logger.error("Error al preparar alerta de Discord para #{name}: #{e.message}")
end

def send_discord_latency_alert(latency_ms)
  return unless notify_discord? && target_discord_webhook.present?

  payload = {
    embeds: [
      {
        title: "⚠️ Latencia Alta Detectada: #{name}",
        description: "El dominio **#{url}** ha registrado una latencia de **#{latency_ms} ms**, superando el límite configurado.",
        color: 15105570, # Ámbar
        timestamp: Time.current.iso8601,
        fields: [
          { name: "Latencia medida", value: "#{latency_ms} ms", inline: true },
          { name: "URL", value: url, inline: true }
        ]
      }
    ]
  }

  DiscordNotificationJob.perform_later(target_discord_webhook, payload)
rescue StandardError => e
  Rails.logger.error("Error al preparar alerta de latencia Discord para #{name}: #{e.message}")
end
  def send_telegram_alert(type)
    return unless notify_telegram? && telegram_bot_token.present? && target_telegram_chat_id.present?

    title = type == :up ? "🟢 *Dominio Recuperado: #{name}*" : "🔴 *Dominio Caído: #{name}*"
    status_desc = type == :up ? "El dominio vuelve a responder con normalidad." : "El dominio no responde o devuelve un código de error."

    msg = <<~TEXT
      #{title}

      #{status_desc}
      • *Estado actual:* `#{status.to_s.upcase}`
      • *URL:* #{url}
      • *Fecha:* `#{Time.current.strftime("%d/%m/%Y %H:%M:%S")}`
    TEXT

    TelegramNotificationJob.perform_later(target_telegram_bot_token, target_telegram_chat_id, msg)
  rescue StandardError => e
    Rails.logger.error("Error al preparar alerta Telegram para #{name}: #{e.message}")
  end

  def send_telegram_latency_alert(latency_ms)
    return unless notify_telegram? && telegram_bot_token.present? && target_telegram_chat_id.present?

    msg = <<~TEXT
      ⚠️ *Alerta de Latencia Alta: #{name}*

      El dominio ha registrado una latencia de *#{latency_ms} ms*, superando el umbral.
      • *URL:* #{url}
      • *Fecha:* `#{Time.current.strftime("%d/%m/%Y %H:%M:%S")}`
    TEXT

    TelegramNotificationJob.perform_later(target_telegram_bot_token, target_telegram_chat_id, msg)
  rescue StandardError => e
    Rails.logger.error("Error al preparar alerta de latencia Telegram para #{name}: #{e.message}")
  end
def send_discord_ssl_alert(days)
  return unless notify_discord? && target_discord_webhook.present?

  payload = {
    embeds: [
      {
        title: "🔐 Advertencia SSL: #{name}",
        description: "El certificado SSL de **#{url}** está próximo a caducar.",
        color: 16753920,
        timestamp: Time.current.iso8601,
        fields: [
          { name: "Días restantes", value: "#{days} días", inline: true },
          { name: "Emisor", value: ssl_issuer.to_s.presence || "Desconocido", inline: true },
          { name: "Caduca el", value: ssl_expires_at ? ssl_expires_at.strftime("%d/%m/%Y") : "N/D", inline: false }
        ]
      }
    ]
  }

  DiscordNotificationJob.perform_later(target_discord_webhook, payload)
rescue StandardError => e
  Rails.logger.error("Error al preparar alerta SSL Discord para #{name}: #{e.message}")
end

def send_telegram_ssl_alert(days)
  return unless notify_telegram? && telegram_bot_token.present? && target_telegram_chat_id.present?

  formatted_date = ssl_expires_at ? ssl_expires_at.strftime("%d/%m/%Y") : "N/D"
  issuer_name = ssl_issuer.presence || "Desconocido"

  msg = "🔐 *Advertencia de Certificado SSL: " + name.to_s + "*

"         "El certificado SSL está próximo a caducar.
"         "• *Días restantes:* *" + days.to_s + " días*
"         "• *Emisor:* " + issuer_name.to_s + "
"         "• *Caduca el:* `" + formatted_date.to_s + "`
"         "• *URL:* " + url.to_s + "
"

  TelegramNotificationJob.perform_later(target_telegram_bot_token, target_telegram_chat_id, msg)
rescue StandardError => e
  Rails.logger.error("Error al preparar alerta SSL Telegram para #{name}: #{e.message}")
end
  def create_status_history
  lat = current_response_time_ms || (has_attribute?(:last_response_time_ms) ? last_response_time_ms : 0)
  update_column(:last_response_time_ms, current_response_time_ms) if column_names.include?("last_response_time_ms") && current_response_time_ms.present? if has_attribute?(:last_response_time_ms) && current_response_time_ms.present?

  status_histories.create(
    status: status,
    response_time_ms: lat || 0,
    http_code: current_http_code || 200,
    recorded_at: Time.current
  )
rescue StandardError => e
    Rails.logger.error("Error al registrar status history para #{name}: #{e.message}")
  end

  private


  def normalize_url
    return if url.blank?

    clean_url = url.to_s.strip
    clean_url = "https://#{clean_url}" unless clean_url.match?(%r{\Ahttps?://}i)
    self.url = clean_url
  end

  def generate_public_token
    self.public_token ||= SecureRandom.alphanumeric(32)
  end

  validate :check_user_domain_limit, on: :create

  private

  def check_user_domain_limit
    return unless user
    if user.domains.count >= user.domain_limit
      errors.add(:base, "Has alcanzado el límite máximo de #{user.domain_limit} dominios para tu plan actual.")
    end
  end

end
