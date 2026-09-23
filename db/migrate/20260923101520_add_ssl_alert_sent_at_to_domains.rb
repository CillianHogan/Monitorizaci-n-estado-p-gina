class AddSslAlertSentAtToDomains < ActiveRecord::Migration[8.0]
  def change
    add_column :domains, :ssl_alert_sent_at, :date
  end
end
