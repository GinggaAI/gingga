module Brands
  class SelectionService
    def initialize(user:, brand_id:)
      @user = user
      @brand_id = brand_id
    end

    def call
      return failure_result("User is required") unless user

      brand = find_brand
      return failure_result("Brand not found or not accessible") unless brand

      if user.update_last_brand(brand)
        success_result(brand: brand)
      else
        failure_result("Failed to update brand selection")
      end
    rescue StandardError => e
      failure_result("An error occurred: #{e.message}")
    end

    private

    attr_reader :user, :brand_id

    def find_brand
      return nil unless brand_id.present?
      user.brands.find_by(id: brand_id)
    end

    def success_result(data)
      { success: true, data: data, error: nil }
    end

    def failure_result(error_message)
      { success: false, data: nil, error: error_message }
    end
  end
end