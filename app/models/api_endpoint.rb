# frozen_string_literal: true

class ApiEndpoint < ApplicationRecord

  HIGH_LATENCY_THRESHOLD_MS = 2000

  def latency_threshold
    HIGH_LATENCY_THRESHOLD_MS
  end

  before_validation :generate_public_token, on: :create
  validates :public_token, uniqueness: true, allow_nil: true
  belongs_to :user
  has_many :status_histories, class_name: 'ApiEndpointStatusHistory', dependent: :destroy

  validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp, message: 'must be a valid URL' }
  validates :name, presence: true

  enum :status, { pending: 0, up: 1, down: 2, error: 3 }, prefix: true
  enum :http_method, { get: 0, post: 1, put: 2, patch: 3, remove: 4 }, default: :get

  after_update_commit :notify_status_change, if: -> { saved_change_to_status? }

  # --- Métodos de resolución de jerarquía de canales ---
  def target_email
    return notify_email_address if notify_email_address.present?
    user&.notification_channels&.default_for(:email)&.destination || user&.email
  end

  def target_discord_webhook
    return discord_webhook_url if discord_webhook_url.present?
    user&.notification_channels&.default_for(:discord)&.destination
  end

  def target_telegram_chat_id
    return telegram_chat_id if telegram_chat_id.present?
    user&.notification_channels&.default_for(:telegram)&.destination
  end

  def target_telegram_bot_token
    telegram_bot_token.presence || ENV["TELEGRAM_BOT_TOKEN"]
  end

  # --- Chequeo HTTP y métricas ---
  def check_status!
    clean_url = url.to_s.strip
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    
    headers_hash = headers.is_a?(Hash) ? headers : {}
    response = case http_method.to_sym
               when :post then HTTParty.post(clean_url, headers: headers_hash, timeout: 10)
               when :put then HTTParty.put(clean_url, headers: headers_hash, timeout: 10)
               when :patch then HTTParty.patch(clean_url, headers: headers_hash, timeout: 10)
               when :remove then HTTParty.delete(clean_url, headers: headers_hash, timeout: 10)
               else HTTParty.get(clean_url, headers: headers_hash, timeout: 10)
               end

    end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    latency = ((end_time - start_time) * 1000).to_i

    new_status = validate_response?(response) ? :up : :down

    update(
      status: new_status,
      last_response_time_ms: latency,
      last_http_code: response.code
    )

    if new_status == :up && latency > latency_threshold
      send_discord_alert(:slow)
      send_telegram_alert(:slow)
    end

    status_histories.create(
      status: new_status,
      response_time_ms: latency,
      http_code: response.code,
      recorded_at: Time.current
    )
  rescue StandardError => e
    Rails.logger.error("API Endpoint check failed for #{clean_url}: #{e.message}")
    update(status: :error, last_http_code: nil)
    status_histories.create(
      status: :error,
      response_time_ms: nil,
      http_code: nil,
      recorded_at: Time.current
    )
  end

  # --- Disparadores de Notificaciones ---
    def send_discord_alert(type)
    return unless notify_discord? && target_discord_webhook.present?

    case type.to_sym
    when :up
      color = 3066993 # Verde
      title = "🟢 Endpoint Recuperado: #{name}"
      desc  = "El endpoint API vuelve a responder correctamente."
    when :slow, :high_latency
      color = 16753920 # Ámbar
      title = "⚠️ Latencia Alta Detectada: #{name}"
      desc  = "El endpoint respondió correctamente pero superó el umbral (#{last_response_time_ms} ms > #{latency_threshold} ms)."
    else
      color = 15158332 # Rojo
      title = "🔴 Endpoint Fallando: #{name}"
      desc  = "El endpoint API no responde o devuelve un error."
    end

    payload = {
      embeds: [
        {
          title: title,
          description: desc,
          color: color,
          timestamp: Time.current.iso8601,
          fields: [
            { name: "Método", value: http_method.to_s.upcase, inline: true },
            { name: "Estado actual", value: status.to_s.upcase, inline: true },
            { name: "Código HTTP", value: last_http_code.to_s.presence || "Error", inline: true },
            { name: "URL", value: url, inline: false }
          ]
        }
      ]
    }

    DiscordNotificationJob.perform_later(target_discord_webhook, payload)
  rescue StandardError => e
    Rails.logger.error("Error al preparar alerta Discord para endpoint #{name}: #{e.message}")
  endpoint #{name}: #{e.message}")
  end

    def send_telegram_alert(type)
    return unless notify_telegram? && target_telegram_bot_token.present? && target_telegram_chat_id.present?

    case type.to_sym
    when :up
      title = "🟢 *Endpoint API Recuperado: #{name}*"
      status_desc = "El endpoint vuelve a responder con éxito."
    when :slow, :high_latency
      title = "⚠️ *Alta Latencia Detectada: #{name}*"
      status_desc = "El endpoint respondió pero con lentitud excesiva (`#{last_response_time_ms} ms > #{latency_threshold} ms`)."
    else
      title = "🔴 *Endpoint API Fallando: #{name}*"
      status_desc = "El endpoint no responde como se esperaba."
    end

    msg = <<~TEXT
      #{title}

      #{status_desc}
      • *Método:* `#{http_method.to_s.upcase}`
      • *Estado:* `#{status.to_s.upcase}`
      • *Código HTTP:* `#{last_http_code || 'Error'}`
      • *URL:* #{url}
      • *Fecha:* `#{Time.current.strftime("%d/%m/%Y %H:%M:%S")}`
    TEXT

    TelegramNotificationJob.perform_later(target_telegram_bot_token, target_telegram_chat_id, msg)
  rescue StandardError => e
    Rails.logger.error("Error al preparar alerta Telegram para endpoint #{name}: #{e.message}")
  endpoint #{name}: #{e.message}")
  end

  private

  def notify_status_change
    case status.to_sym
    when :error, :down
      ApiEndpointMailer.status_error_notification(self).deliver_later if notify_email? && target_email.present?
      send_discord_alert(:down)
      send_telegram_alert(:down)
    when :up
      # Opcional: alerta de recuperación si venía de un fallo
      send_discord_alert(:up)
      send_telegram_alert(:up)
    end
  end

  def validate_response?(response)
    response.success? && validate_expected_response?(response)
  end

  def validate_expected_response?(response)
    return true if expected_response.blank?

    expected_response.all? { |key, value| response[key] == value }
  end
  def generate_public_token
    self.public_token ||= SecureRandom.alphanumeric(32)
  end

  validate :check_user_api_endpoint_limit, on: :create

  private

  def check_user_api_endpoint_limit
    return unless user
    if user.api_endpoints.count >= user.api_endpoint_limit
      errors.add(:base, "Has alcanzado el límite máximo de #{user.api_endpoint_limit} endpoints API para tu plan actual.")
    end
  end

end
