class AddCounterCachesToBrands < ActiveRecord::Migration[8.0]
  def change
    add_column :brands, :audiences_count, :integer, null: false, default: 0
    add_column :brands, :products_count, :integer, null: false, default: 0
    add_column :brands, :brand_channels_count, :integer, null: false, default: 0

    # Reset counter cache for existing records
    reversible do |dir|
      dir.up do
        Brand.find_each do |brand|
          Brand.reset_counters(brand.id, :audiences, :products, :brand_channels)
        end
      end
    end
  end
end
