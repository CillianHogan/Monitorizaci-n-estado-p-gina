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
    
    # Simplemente contar la proporción de registros 'up' respecto al total
    up_count = histories.count { |h| h.status == 'up' }
    total_count = histories.size
    
    # Calcular el porcentaje de tiempo de actividad
    (up_count.to_f / total_count) * 100
  end
  
  # Método alternativo que calcula el uptime ponderado por tiempo entre registros
  def calculate_weighted_uptime_percentage(histories)
    return 100.0 if histories.empty?
    
    # Si solo hay un registro, usamos su estado para determinar el uptime
    if histories.size == 1
      # Si el registro es reciente (últimas 24 horas), consideramos su estado actual
      if (Time.current - histories.first.recorded_at) < 24.hours
        return histories.first.status == 'up' ? 100.0 : 0.0
      else
        # Si el registro es antiguo, asumimos un uptime del 50% para evitar valores extremos
        # basados en datos insuficientes
        return 50.0
      end
    end
    
    # Ordenar historiales por tiempo de registro
    sorted_histories = histories.sort_by(&:recorded_at)
    
    total_time = 0.0
    uptime = 0.0
    
    # Calcular el tiempo ponderado entre cada par de registros consecutivos
    (0...(sorted_histories.size - 1)).each do |i|
      current = sorted_histories[i]
      next_record = sorted_histories[i + 1]
      
      # Calcular el tiempo entre este registro y el siguiente
      time_diff = (next_record.recorded_at - current.recorded_at).to_f
      
      # Si el estado actual es 'up', añadir este tiempo al uptime
      uptime += time_diff if current.status == 'up'
      
      # Añadir este tiempo al tiempo total
      total_time += time_diff
    end
    
    # Para el último registro, asumimos que su estado se mantiene hasta ahora
    # Consideramos el último registro independientemente de su antigüedad
    last_time_diff = (Time.current - sorted_histories.last.recorded_at).to_f
    uptime += last_time_diff if sorted_histories.last.status == 'up'
    total_time += last_time_diff
    
    return 50.0 if total_time.zero? # Valor predeterminado si no hay tiempo total calculable
    
    # Calcular el porcentaje de tiempo de actividad
    (uptime / total_time) * 100
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
  
  helper_method :calculate_uptime_percentage, :calculate_weighted_uptime_percentage
end