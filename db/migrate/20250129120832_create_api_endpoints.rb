class CreateApiEndpoints < ActiveRecord::Migration[8.0]
  def change
    create_table :api_endpoints do |t|
      t.string :name
      t.string :url
      t.integer :status, default: 0
      t.integer :http_method, default: 0
      t.json :headers
      t.json :expected_response
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
