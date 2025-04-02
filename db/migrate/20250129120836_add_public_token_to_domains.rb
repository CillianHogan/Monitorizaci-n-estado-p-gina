class AddPublicTokenToDomains < ActiveRecord::Migration[8.0]
  def change
    add_column :domains, :public_token, :string
    add_index :domains, :public_token, unique: true
  end
end