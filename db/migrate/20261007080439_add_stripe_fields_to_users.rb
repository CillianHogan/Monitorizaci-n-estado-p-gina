class AddStripeFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :stripe_customer_id, :string
    add_index :users, :stripe_customer_id
    add_column :users, :stripe_subscription_id, :string
    add_index :users, :stripe_subscription_id
  end
end
