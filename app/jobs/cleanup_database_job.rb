# frozen_string_literal: true

class CleanupDatabaseJob < ApplicationJob
  queue_as :default

  def perform
    retention_cutoff = 7.days.ago

    # 1. Purgar historiales de estado de dominios antiguos (> 7 días)
    deleted_domains = DomainStatusHistory.where("recorded_at < ?", retention_cutoff).delete_all
    Rails.logger.info("CleanupDatabaseJob: Eliminados #{deleted_domains} registros antiguos de domain_status_histories.")

    # 2. Purgar historiales de endpoints API antiguos (> 7 días)
    deleted_endpoints = ApiEndpointStatusHistory.where("recorded_at < ?", retention_cutoff).delete_all
    Rails.logger.info("CleanupDatabaseJob: Eliminados #{deleted_endpoints} registros antiguos de api_endpoint_status_histories.")

    # 3. Limpieza de seguridad: mantener como máximo 500 registros por dominio
    Domain.find_each do |domain|
      excess_ids = domain.status_histories.order(recorded_at: :desc).offset(500).pluck(:id)
      domain.status_histories.where(id: excess_ids).delete_all if excess_ids.any?
    end

    # 4. Limpieza de seguridad: mantener como máximo 500 registros por endpoint
    ApiEndpoint.find_each do |endpoint|
      excess_ids = endpoint.status_histories.order(recorded_at: :desc).offset(500).pluck(:id)
      endpoint.status_histories.where(id: excess_ids).delete_all if excess_ids.any?
    end

    # 5. Purgar jobs antiguos finalizados de SolidQueue (conservar solo últimas 6 horas)
    if defined?(SolidQueue::Job)
      SolidQueue::Job.clear_finished_in_batches(finished_before: 1.hour.ago) rescue nil
      Rails.logger.info("CleanupDatabaseJob: Purgados jobs finalizados de SolidQueue.")
    end
  end
end
