# frozen_string_literal: true

class PublicStatusController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :set_domain

  def show
    @status_histories = @domain.status_histories.order(recorded_at: :desc).limit(30)
    @last_90_days_histories = @domain.status_histories.where('recorded_at >= ?', 90.days.ago).order(recorded_at: :asc)
    @last_30_days_histories = @domain.status_histories.where('recorded_at >= ?', 30.days.ago).order(recorded_at: :asc)
    @last_7_days_histories = @domain.status_histories.where('recorded_at >= ?', 7.days.ago).order(recorded_at: :asc)
    @last_24_hours_histories = @domain.status_histories.where('recorded_at >= ?', 24.hours.ago).order(recorded_at: :asc)
    
    # Calculate downtime duration for incidents
    @incidents = calculate_incidents
  end

  private

  def set_domain
    @domain = Domain.find_by!(public_token: params[:token])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: 'Página de estado no encontrada'
  end
  
  def calculate_uptime_percentage(histories)
    return 100.0 if histories.empty?
    
    up_count = histories.count { |h| h.status == 'up' }
    (up_count.to_f / histories.size) * 100
  end
  
  def calculate_incidents
    incidents = []
    current_incident = nil
    
    @domain.status_histories.order(recorded_at: :asc).each do |history|
      if history.status != 'up' && current_incident.nil?
        # Start of a new incident
        current_incident = { start: history.recorded_at, status: history.status }
      elsif history.status == 'up' && current_incident.present?
        # End of an incident
        current_incident[:end] = history.recorded_at
        current_incident[:duration] = ((current_incident[:end] - current_incident[:start]) / 60).round # in minutes
        incidents << current_incident
        current_incident = nil
      end
    end
    
    # Handle ongoing incident
    if current_incident.present?
      current_incident[:end] = Time.current
      current_incident[:duration] = ((current_incident[:end] - current_incident[:start]) / 60).round # in minutes
      incidents << current_incident
    end
    
    incidents.sort_by { |i| i[:start] }.reverse
  end
  
  helper_method :calculate_uptime_percentage
end