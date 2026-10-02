class AddPublicTokenToApiEndpoints < ActiveRecord::Migration[8.0]
  def change
    add_column :api_endpoints, :public_token, :string
    add_index :api_endpoints, :public_token, unique: true

    reversible do |dir|
      dir.up do
        ApiEndpoint.reset_column_information
        ApiEndpoint.find_each do |ep|
          ep.update_column(:public_token, SecureRandom.alphanumeric(32))
        end
      end
    end
  end
end
