class AddNotificationChannelsToApiEndpoints < ActiveRecord::Migration[8.0]
  def change
    add_column :api_endpoints, :notify_email, :boolean, default: true, null: false
    add_column :api_endpoints, :notify_email_address, :string
    add_column :api_endpoints, :notify_discord, :boolean, default: false, null: false
    add_column :api_endpoints, :discord_webhook_url, :string
    add_column :api_endpoints, :notify_telegram, :boolean, default: false, null: false
    add_column :api_endpoints, :telegram_chat_id, :string
    add_column :api_endpoints, :telegram_bot_token, :string
    add_column :api_endpoints, :last_response_time_ms, :integer
    add_column :api_endpoints, :last_http_code, :integer
  end
end
