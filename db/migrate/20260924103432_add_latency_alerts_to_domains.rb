class AddLatencyAlertsToDomains < ActiveRecord::Migration[8.0]
  def change
    add_column :domains, :max_latency_threshold_ms, :integer
    add_column :domains, :latency_alert_sent_at, :datetime
  end
end
