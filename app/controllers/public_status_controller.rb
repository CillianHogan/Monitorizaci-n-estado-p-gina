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
    
    # Para períodos cortos (menos de 48 horas), calculamos por hora en lugar de por día
    if histories.last.recorded_at - histories.first.recorded_at < 48.hours && histories.size > 1
      # Agrupar por hora para períodos cortos
      time_unit = :hour
      histories_by_unit = histories.group_by { |h| h.recorded_at.beginning_of_hour }
    else
      # Agrupar registros por día para períodos más largos
      time_unit = :day
      histories_by_unit = histories.group_by { |h| h.recorded_at.to_date }
    end
    
    # Calcular el estado predominante para cada unidad de tiempo
    units_up = 0
    total_units = histories_by_unit.size
    
    histories_by_unit.each do |time, unit_histories|
      # Una unidad de tiempo se considera 'up' si la mayoría de los registros están 'up'
      up_count = unit_histories.count { |h| h.status == 'up' }
      units_up += 1 if up_count > unit_histories.size / 2.0
    end
    
    # Calcular el porcentaje de unidades de tiempo con estado predominante 'up'
    (units_up.to_f / total_units) * 100
  end
  
  def calculate_incidents
    incidents = []
    current_incident = nil
    last_status = nil
    min_incident_duration = 2.minutes # Ignorar fluctuaciones muy breves
    
    @domain.status_histories.order(recorded_at: :asc).each do |history|
      # Iniciar un nuevo incidente cuando el estado cambia de 'up' a cualquier otro
      if history.status != 'up' && (last_status == 'up' || last_status.nil?) && current_incident.nil?
        # Start of a new incident
        current_incident = { 
          start: history.recorded_at, 
          status: history.status,
          details: "El servicio cambió de estado a #{history.status}"
        }
      # Finalizar un incidente cuando el estado cambia a 'up'
      elsif history.status == 'up' && current_incident.present?
        # End of an incident
        current_incident[:end] = history.recorded_at
        current_incident[:duration] = ((current_incident[:end] - current_incident[:start]) / 60.0).round # in minutes
        
        # Solo registrar incidentes que duren más que el mínimo establecido
        if (current_incident[:end] - current_incident[:start]) >= min_incident_duration
          incidents << current_incident
        end
        current_incident = nil
      # Actualizar el estado del incidente si cambia durante el mismo
      elsif history.status != 'up' && current_incident.present? && history.status != current_incident[:status]
        current_incident[:status] = history.status
        current_incident[:details] = "#{current_incident[:details]}. Cambió a #{history.status} en #{history.recorded_at.strftime('%H:%M')}"
      end
      
      last_status = history.status
    end
    
    # Handle ongoing incident
    if current_incident.present?
      current_incident[:end] = Time.current
      current_incident[:duration] = ((current_incident[:end] - current_incident[:start]) / 60.0).round # in minutes
      current_incident[:ongoing] = true
      incidents << current_incident if (current_incident[:end] - current_incident[:start]) >= min_incident_duration
    end
    
    incidents.sort_by { |i| i[:start] }.reverse
  end
  
  helper_method :calculate_uptime_percentage
end