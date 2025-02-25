class CreateDomainStatusHistories < ActiveRecord::Migration[8.0]
  def change
    create_table :domain_status_histories do |t|
      t.references :domain, null: false, foreign_key: true
      t.integer :status
      t.datetime :recorded_at

      t.timestamps
    end
  end
end