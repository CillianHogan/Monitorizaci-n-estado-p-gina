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
    @status_histories = @domain.status_histories.order(recorded_at: :desc).limit(30)
    
    @last_90_days_histories = @domain.status_histories.where("recorded_at >= ?", 90.days.ago).order(recorded_at: :asc).limit(200)
    @last_30_days_histories = @last_90_days_histories
    @last_7_days_histories = @domain.status_histories.where("recorded_at >= ?", 7.days.ago).order(recorded_at: :asc).limit(100)
    @last_24_hours_histories = @domain.status_histories.where("recorded_at >= ?", 24.hours.ago).order(recorded_at: :asc).limit(50)

    @uptime_24h = calculate_sql_uptime(24.hours.ago)
    @uptime_7d  = calculate_sql_uptime(7.days.ago)
    @uptime_30d = calculate_sql_uptime(30.days.ago)
    @uptime_90d = calculate_sql_uptime(90.days.ago)

    @incidents = calculate_incidents
  end

  private

  def set_domain
    @domain = Domain.find_by!(public_token: params[:token])
  rescue ActiveRecord::RecordNotFound
    redirect_to status_path, alert: "Página de estado no encontrada"
  end

  def calculate_sql_uptime(since_time)
    total = @domain.status_histories.where("recorded_at >= ?", since_time).count
    return 100.0 if total.zero?

    up_count = @domain.status_histories.where("recorded_at >= ?", since_time).where(status: "up").count
    ((up_count.to_f / total) * 100).round(2)
  end

  def calculate_incidents
    incidents = []
    current_incident = nil

    # Evaluamos solo los ultimos 100 registros para evitar consumo de RAM
    sample = @domain.status_histories.order(recorded_at: :desc).limit(100).to_a.reverse

    sample.each do |h|
      if h.status != "up"
        if current_incident.nil?
          current_incident = {
            title: "Outage detected",
            start: h.recorded_at,
            end: nil,
            duration: nil,
            ongoing: true
          }
        end
      elsif current_incident.present?
        current_incident[:end] = h.recorded_at
        current_incident[:duration] = ((current_incident[:end] - current_incident[:start]) / 60).round
        current_incident[:ongoing] = false
        incidents << current_incident
        current_incident = nil
      end
    end

    incidents << current_incident if current_incident.present?
    incidents.reverse
  end
end
