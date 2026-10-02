class CreateNotificationChannels < ActiveRecord::Migration[8.0]
  def change
    create_table :notification_channels do |t|
      t.references :user, null: false, foreign_key: true
      t.string :channel_type, null: false
      t.string :destination, null: false
      t.string :name
      t.boolean :is_default, default: false, null: false

      t.timestamps
    end

    add_index :notification_channels, [:user_id, :channel_type]
  end
end
