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
    
    # Calcular el tiempo total de actividad
    total_up_time = 0.0
    total_time = 0.0
    
    histories_by_unit.each do |time, unit_histories|
      # Calcular el porcentaje de tiempo 'up' para esta unidad de tiempo
      up_count = unit_histories.count { |h| h.status == 'up' }
      unit_up_percentage = (up_count.to_f / unit_histories.size) * 100
      
      # Acumular el tiempo ponderado
      total_up_time += unit_up_percentage
      total_time += 100.0 # Cada unidad representa 100%
    end
    
    # Calcular el porcentaje global de tiempo de actividad
    (total_up_time / total_time) * 100
  end
  
  def calculate_incidents
    incidents = []
    current_incident = nil
    last_status = nil
    last_recorded_at = nil
    min_incident_duration = 2.minutes # Ignorar fluctuaciones muy breves
    stability_threshold = 5.minutes # Tiempo mínimo para considerar un estado como estable
    
    @domain.status_histories.order(recorded_at: :asc).each do |history|
      # Si es el primer registro, solo guardamos el estado
      if last_status.nil?
        last_status = history.status
        last_recorded_at = history.recorded_at
        next
      end
      
      # Calcular el tiempo transcurrido desde el último registro
      time_since_last = history.recorded_at - last_recorded_at
      
      # Iniciar un nuevo incidente cuando el estado cambia de 'up' a cualquier otro
      if history.status != 'up' && last_status == 'up' && current_incident.nil?
        # Start of a new incident
        current_incident = { 
          start: history.recorded_at, 
          status: history.status,
          details: "El servicio cambió de estado a #{history.status}"
        }
      # Finalizar un incidente cuando el estado cambia a 'up' y ha pasado suficiente tiempo para considerarlo estable
      elsif history.status == 'up' && current_incident.present? && time_since_last >= stability_threshold
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
      last_recorded_at = history.recorded_at
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