class AddTelegramNotificationsToDomains < ActiveRecord::Migration[8.0]
  def change
    add_column :domains, :telegram_bot_token, :string
    add_column :domains, :telegram_chat_id, :string
    add_column :domains, :notify_telegram, :boolean, default: false, null: false
  end
end
