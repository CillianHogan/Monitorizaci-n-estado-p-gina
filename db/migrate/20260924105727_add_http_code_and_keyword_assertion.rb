class AddHttpCodeAndKeywordAssertion < ActiveRecord::Migration[8.0]
  def change
    add_column :domain_status_histories, :http_code, :integer
    add_column :domains, :expected_keyword, :string
  end
end
