class AddLastBrandIdToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :last_brand_id, :uuid
    add_foreign_key :users, :brands, column: :last_brand_id, on_delete: :nullify
    add_index :users, :last_brand_id
  end
end
