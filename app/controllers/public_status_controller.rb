# frozen_string_literal: true

class PublicStatusController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :set_resource, only: [:show]

  def index
    @domains = Domain.order(:name)
    @api_endpoints = ApiEndpoint.order(:name)
    
    all_resources = @domains.to_a + @api_endpoints.to_a
    @total_count = all_resources.size
    @operational_count = all_resources.count(&:status_up?)
    @down_resources = all_resources.reject(&:status_up?)
    @all_operational = @down_resources.empty?
  end

  def show
    # Soporte unificado para Domain y ApiEndpoint
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
  end

  private

  def set_resource
    @domain = Domain.find_by(public_token: params[:token]) || ApiEndpoint.find_by(public_token: params[:token])
    if @domain.nil?
      redirect_to status_path, alert: "Página de estado no encontrada"
    end
  end

  def calculate_sql_uptime(since_time)
    scope = @domain.status_histories.where("recorded_at >= ?", since_time)
    total = scope.count
    return (@domain.status_up? ? 100.0 : 0.0) if total.zero?

    up_count = scope.where(status: "up").count
    ((up_count.to_f / total) * 100).round(2)
  end

  def calculate_incidents
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
