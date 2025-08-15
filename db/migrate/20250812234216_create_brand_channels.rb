class CreateBrandChannels < ActiveRecord::Migration[8.0]
  def change
    create_table :brand_channels, id: :uuid do |t|
      t.references :brand, null: false, type: :uuid, foreign_key: true
      t.integer :platform, null: false, default: 0 # enum: instagram,tiktok,youtube,linkedin
      t.string  :handle
      t.integer :priority, null: false, default: 1
      t.timestamps
    end
    add_index :brand_channels, [ :brand_id, :platform ], unique: true
  end
end
