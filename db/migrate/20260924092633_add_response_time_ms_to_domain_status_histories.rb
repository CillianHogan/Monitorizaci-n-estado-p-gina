class AddResponseTimeMsToDomainStatusHistories < ActiveRecord::Migration[8.0]
  def change
    add_column :domain_status_histories, :response_time_ms, :integer
  end
end
