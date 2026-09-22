class AddSslFieldsToDomains < ActiveRecord::Migration[8.0]
  def change
    add_column :domains, :ssl_valid, :boolean
    add_column :domains, :ssl_issuer, :string
    add_column :domains, :ssl_expires_at, :datetime
    add_column :domains, :ssl_days_remaining, :integer
  end
end
