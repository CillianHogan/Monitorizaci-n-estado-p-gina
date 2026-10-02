class AddLastResponseTimeToDomains < ActiveRecord::Migration[8.0]
  def change
    add_column :domains, :last_response_time_ms, :integer
  end
end
