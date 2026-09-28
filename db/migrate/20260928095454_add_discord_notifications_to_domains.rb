class AddDiscordNotificationsToDomains < ActiveRecord::Migration[8.0]
  def change
    add_column :domains, :discord_webhook_url, :string
    add_column :domains, :notify_discord, :boolean, default: false, null: false
  end
end
