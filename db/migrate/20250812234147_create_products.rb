class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products, id: :uuid do |t|
      t.references :brand, null: false, type: :uuid, foreign_key: true
      t.string :name, null: false
      t.text   :description
      t.string :pricing_info
      t.string :url
      t.timestamps
    end
    add_index :products, [ :brand_id, :name ], unique: true
  end
end
