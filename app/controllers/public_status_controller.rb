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
    @last_90_days_histories = @domain.status_histories.where(recorded_at: 90.days.ago..).order(recorded_at: :asc)
    @last_30_days_histories = @domain.status_histories.where(recorded_at: 30.days.ago..).order(recorded_at: :asc)
    @last_7_days_histories = @domain.status_histories.where(recorded_at: 7.days.ago..).order(recorded_at: :asc)
    @last_24_hours_histories = @domain.status_histories.where(recorded_at: 24.hours.ago..).order(recorded_at: :asc)

    @incidents = calculate_incidents
  end

  private

  def set_domain
    @domain = Domain.find_by!(public_token: params[:token])
  rescue ActiveRecord::RecordNotFound
    redirect_to status_path, alert: "Página de estado no encontrada"
  end

  def calculate_uptime_percentage(histories)
    return 100.0 if histories.empty?

    up_count = histories.count { |h| h.status == "up" }
    (up_count.to_f / histories.size) * 100
  end

  def calculate_weighted_uptime_percentage(histories)
    return 100.0 if histories.empty?
    return (histories.first.status == "up" ? 100.0 : 0.0) if histories.size == 1

    sorted = histories.sort_by(&:recorded_at)
    total_time = 0.0
    uptime = 0.0

    (0...(sorted.size - 1)).each do |i|
      curr = sorted[i]
      diff = (sorted[i + 1].recorded_at - curr.recorded_at).to_f
      uptime += diff if curr.status == "up"
      total_time += diff
    end

    last_diff = (Time.current - sorted.last.recorded_at).to_f
    uptime += last_diff if sorted.last.status == "up"
    total_time += last_diff

    total_time.zero? ? 50.0 : ((uptime / total_time) * 100)
  end

  def calculate_incidents
    incidents = []
    current_incident = nil
    last_status = nil
    last_recorded_at = nil
    min_incident_duration = 2.minutes
    stability_threshold = 5.minutes

    @domain.status_histories.order(recorded_at: :asc).each do |history|
      if last_status.nil?
        last_status = history.status
        last_recorded_at = history.recorded_at
        next
      end

      time_since_last = history.recorded_at - last_recorded_at

      if history.status != "up" && last_status == "up" && current_incident.nil?
        current_incident = {
          start: history.recorded_at,
          status: history.status,
          details: "El servicio cambió de estado a #{history.status}"
        }
      elsif history.status == "up" && current_incident.present? && time_since_last >= stability_threshold
        current_incident[:end] = history.recorded_at
        current_incident[:duration] = ((current_incident[:end] - current_incident[:start]) / 60.0).round
        incidents << current_incident if (current_incident[:end] - current_incident[:start]) >= min_incident_duration
        current_incident = nil
      elsif history.status != "up" && current_incident.present? && history.status != current_incident[:status]
        current_incident[:status] = history.status
        current_incident[:details] = "#{current_incident[:details]}. Cambió a #{history.status} en #{history.recorded_at.strftime('%H:%M')}"
      end

      last_status = history.status
      last_recorded_at = history.recorded_at
    end

    if current_incident.present?
      current_incident[:end] = Time.current
      current_incident[:duration] = ((current_incident[:end] - current_incident[:start]) / 60.0).round
      current_incident[:ongoing] = true
      incidents << current_incident if (current_incident[:end] - current_incident[:start]) >= min_incident_duration
    end

    incidents.sort_by { |i| i[:start] }.reverse
  end

  helper_method :calculate_uptime_percentage, :calculate_weighted_uptime_percentage
end
