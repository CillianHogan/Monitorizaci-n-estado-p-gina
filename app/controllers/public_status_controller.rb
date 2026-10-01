# frozen_string_literal: true

class PublicStatusController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :set_domain, only: [:show]

  def index
    @domains = Domain.order(:name)
    @down_domains = @domains.select { |d| d.status_down? || d.status_error? }
    @all_operational = @down_domains.empty?
    @total_count = @domains.count
    @operational_count = @domains.count(&:status_up?)
  end

  def show
    if @domain.respond_to?(:status_histories)
      @status_histories = @domain.status_histories.order(recorded_at: :desc).limit(30)
      @last_90_days_histories = @domain.status_histories.where("recorded_at >= ?", 90.days.ago).order(recorded_at: :asc).limit(200)
      @last_30_days_histories = @last_90_days_histories
      @last_7_days_histories  = @domain.status_histories.where("recorded_at >= ?", 7.days.ago).order(recorded_at: :asc).limit(100)
      @last_24_hours_histories = @domain.status_histories.where("recorded_at >= ?", 24.hours.ago).order(recorded_at: :asc).limit(50)

      @uptime_24h = calculate_sql_uptime(24.hours.ago)
      @uptime_7d  = calculate_sql_uptime(7.days.ago)
      @uptime_30d = calculate_sql_uptime(30.days.ago)
      @uptime_90d = calculate_sql_uptime(90.days.ago)

      @incidents = calculate_incidents
    else
      # Soporte seguro para ApiEndpoint (sin histórico relacional)
      @status_histories = []
      @last_90_days_histories = []
      @last_30_days_histories = []
      @last_7_days_histories  = []
      @last_24_hours_histories = []

      current_uptime = @domain.status_up? ? 100.0 : 0.0
      @uptime_24h = current_uptime
      @uptime_7d  = current_uptime
      @uptime_30d = current_uptime
      @uptime_90d = current_uptime

      @incidents = []
    end
  end

  private

  def set_domain
    @domain = Domain.find_by(public_token: params[:token]) || ApiEndpoint.find_by(public_token: params[:token])
    if @domain.nil?
      redirect_to status_path, alert: "Página de estado no encontrada"
    end
  end

  def calculate_sql_uptime(since_time)
    return (@domain.status.to_s == "up" ? 100.0 : 0.0) unless @domain.respond_to?(:status_histories)

    total = @domain.status_histories.where("recorded_at >= ?", since_time).count
    return (@domain.status.to_s == "up" ? 100.0 : 0.0) if total.zero?

    up_count = @domain.status_histories.where("recorded_at >= ?", since_time).where(status: "up").count
    ((up_count.to_f / total) * 100).round(2)
  end

  def calculate_incidents
    return [] unless @domain.respond_to?(:status_histories)

    incidents = []
    current_incident = nil

    sample = @domain.status_histories.order(recorded_at: :desc).limit(100).to_a.reverse

    sample.each do |h|
      if h.status.to_s != "up"
        if current_incident.nil?
          current_incident = {
            title: "Caída o fallo detectado",
            status: (h.status.presence || "down"),
            start: h.recorded_at || Time.current,
            end: nil,
            duration: 0,
            ongoing: true
          }
        end
      elsif current_incident.present?
        current_incident[:end] = h.recorded_at || Time.current
        current_incident[:duration] = [((current_incident[:end] - current_incident[:start]) / 60).round, 0].max
        current_incident[:ongoing] = false
        incidents << current_incident
        current_incident = nil
      end
    end

    incidents << current_incident if current_incident.present?
    incidents.reverse
  end
end
