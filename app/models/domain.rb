# frozen_string_literal: true

require "securerandom"
require "socket"
require "openssl"
require "httparty"

class Domain < ApplicationRecord
  belongs_to :user
  has_many :status_histories, dependent: :destroy, class_name: "DomainStatusHistory"

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

  def check_status!
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
  end


def check_latency_alert!(latency_ms)
  return unless status_up? && latency_ms.present?
  threshold = max_latency_threshold_ms.presence || 2000
  return if latency_ms <= threshold

  # Cooldown de 2 horas para evitar saturar la bandeja
  return if latency_alert_sent_at.present? && latency_alert_sent_at > 2.hours.ago

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
      DomainMailer.ssl_expiration_warning_notification(self).deliver_later
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

  private

  def normalize_url
    return if url.blank?
    trimmed = url.to_s.strip
    trimmed = "https://#{trimmed}" unless trimmed.match?(%r{\Ahttps?://}i)
    self.url = trimmed
  end

  def generate_public_token
    self.public_token = loop do
      token = SecureRandom.urlsafe_base64(16)
      break token unless Domain.exists?(public_token: token)
    end
  end

  def notify_status_change
    previous_status = saved_change_to_status.first
    current_status = status

    return unless previous_status != current_status && (previous_status == "up" || current_status == "up")

    if current_status == "up"
      DomainMailer.status_up_notification(self).deliver_later
    else
      DomainMailer.status_down_notification(self).deliver_later
    end
  rescue StandardError => e
    Rails.logger.error("Mailer notification failed: #{e.message}")
  end

  def create_status_history
    status_histories.create!(
      status: status,
      recorded_at: Time.current,
      response_time_ms: current_response_time_ms,
      http_code: current_http_code
    )
  rescue StandardError => e
    Rails.logger.error("History recording failed: #{e.message}")
  end

  def check_initial_status
    check_status!
  end
end
