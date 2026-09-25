# frozen_string_literal: true

class CleanupDatabaseJob < ApplicationJob
  queue_as :default

  def perform
    # 1. Purgar historiales de estado de dominios con más de 45 días
    deleted_histories = DomainStatusHistory.where("recorded_at < ?", 45.days.ago).delete_all
    Rails.logger.info("CleanupDatabaseJob: Eliminados #{deleted_histories} registros antiguos de domain_status_histories.")

    # 2. Purgar jobs antiguos finalizados de SolidQueue (conservar solo últimas 24h)
    if defined?(SolidQueue::Job)
      # Elimina ejecuciones completadas o descartadas de más de 1 día
      SolidQueue::Job.clear_finished_in_batches(finished_before: 1.day.ago) rescue nil
      Rails.logger.info("CleanupDatabaseJob: Purgados jobs finalizados de SolidQueue.")
    end
  end
end
