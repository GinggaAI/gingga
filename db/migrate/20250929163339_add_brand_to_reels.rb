class AddBrandToReels < ActiveRecord::Migration[8.0]
  def up
    # Add brand reference as nullable first
    add_reference :reels, :brand, null: true, foreign_key: true, type: :uuid

    # Update existing reels to use the user's current brand
    Reel.reset_column_information
    Reel.includes(:user).find_each do |reel|
      brand = reel.user.current_brand
      if brand
        reel.update_column(:brand_id, brand.id)
      else
        # If user has no brands, use their first brand
        first_brand = reel.user.brands.first
        reel.update_column(:brand_id, first_brand.id) if first_brand
      end
    end

    # Now make brand_id not null
    change_column_null :reels, :brand_id, false
  end

  def down
    remove_reference :reels, :brand, foreign_key: true
  end
end
