class AddNotifyEmailToDomains < ActiveRecord::Migration[8.0]
  def change
    add_column :domains, :notify_email, :boolean, default: true, null: false
  end
end
