class AddBrandToApiTokens < ActiveRecord::Migration[8.0]
  def up
    # Add brand reference as nullable first
    add_reference :api_tokens, :brand, null: true, foreign_key: true, type: :uuid

    # Update existing api_tokens to use the user's current brand
    ApiToken.reset_column_information
    ApiToken.includes(:user).find_each do |token|
      brand = token.user.current_brand
      if brand
        token.update_column(:brand_id, brand.id)
      else
        # If user has no brands, use their first brand
        first_brand = token.user.brands.first
        token.update_column(:brand_id, first_brand.id) if first_brand
      end
    end

    # Now make brand_id not null
    change_column_null :api_tokens, :brand_id, false
  end

  def down
    remove_reference :api_tokens, :brand, foreign_key: true
  end
end
