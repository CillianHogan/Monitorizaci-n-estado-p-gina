class AddAlertControlsToDomains < ActiveRecord::Migration[8.0]
  def change
    add_column :domains, :latency_alert_enabled, :boolean, default: false, null: false
    add_column :domains, :down_alert_sent_at, :datetime
  end
end
