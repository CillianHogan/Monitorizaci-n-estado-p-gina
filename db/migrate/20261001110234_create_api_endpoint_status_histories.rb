class CreateApiEndpointStatusHistories < ActiveRecord::Migration[8.0]
  def change
    create_table :api_endpoint_status_histories do |t|
      t.references :api_endpoint, null: false, foreign_key: true
      t.integer :status, default: 0
      t.integer :response_time_ms
      t.integer :http_code
      t.datetime :recorded_at

      t.timestamps
    end

    add_index :api_endpoint_status_histories, [:api_endpoint_id, :recorded_at]
  end
end
