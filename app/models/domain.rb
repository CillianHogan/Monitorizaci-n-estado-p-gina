# frozen_string_literal: true

require 'securerandom'

class Domain < ApplicationRecord
  belongs_to :user
  has_many :status_histories, dependent: :destroy, class_name: 'DomainStatusHistory'

  validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp, message: 'must be a valid URL' }
  validates :name, presence: true
  validates :public_token, presence: true, uniqueness: true

  enum :status, { pending: 0, up: 1, down: 2, error: 3 }, prefix: true

  before_validation :generate_public_token, on: :create
  after_create :check_initial_status
  after_save :create_status_history

  after_update_commit :notify_status_change, if: -> { saved_change_to_status? }

  def check_status!
    response = HTTParty.head(url)
    update(status: response.success? ? :up : :down)
  rescue StandardError => e
    Rails.logger.error("Domain check failed for #{url}: #{e.message}")
    update(status: :error)
  end

  private

  def generate_public_token
    self.public_token = loop do
      token = SecureRandom.urlsafe_base64(16)
      break token unless Domain.exists?(public_token: token)
    end
  end

  def notify_status_change
    # Solo notificar cuando el estado cambia realmente
    # El callback ya verifica saved_change_to_status?, así que sabemos que hubo un cambio
    previous_status = saved_change_to_status.first
    current_status = status

    # Solo enviar notificación si el estado anterior es diferente al actual
    # y si el estado anterior o actual es "up" (para notificar caídas y recuperaciones)
    return unless previous_status != current_status && (previous_status == 'up' || current_status == 'up')

    if current_status == 'up'
      DomainMailer.status_up_notification(self).deliver_now
    else
      DomainMailer.status_down_notification(self).deliver_now
    end
  end

  def create_status_history
    status_histories.create!(status: status, recorded_at: Time.current)
  end

  def check_initial_status
    check_status!
  end
end
