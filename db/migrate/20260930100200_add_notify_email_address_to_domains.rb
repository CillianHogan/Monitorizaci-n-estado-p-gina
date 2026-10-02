class AddNotifyEmailAddressToDomains < ActiveRecord::Migration[8.0]
  def change
    add_column :domains, :notify_email_address, :string
  end
end
