module Brands
  class RetrievalService
    def initialize(user:, brand_id: nil, eager_load: false)
      @user = user
      @brand_id = brand_id
      @eager_load = eager_load
    end

    def call
      return failure_result("User is required") unless user

      brand = find_brand
      success_result(brand: brand)
    rescue StandardError => e
      failure_result("An error occurred: #{e.message}")
    end

    def self.for_edit(user:, brand_id: nil)
      # Specialized method for edit action that needs eager loading
      service = new(user: user, brand_id: brand_id, eager_load: true)
      result = service.call
      brand = result[:data][:brand] if result[:success]

      # Return existing brand or fall back to new brand with initialized associations
      brand || build_new_brand_with_associations(user)
    end

    def self.collection_for_user(user:)
      # Optimized method for getting brand collections - no associations needed for dropdown
      user.brands.order(:created_at)
    end

    private

    attr_reader :user, :brand_id, :eager_load

    def find_brand
      # No longer need eager loading since we use counter cache for has_* checks
      # and forms will lazy load associations as needed
      if brand_id.present?
        user.brands.find(brand_id)
      else
        user.brands.first
      end
    end

    def self.build_new_brand_with_associations(user)
      brand = user.brands.build
      # Initialize empty association collections to avoid N+1 queries in views
      brand.association(:audiences).target = []
      brand.association(:products).target = []
      brand.association(:brand_channels).target = []
      brand
    end

    def success_result(data)
      { success: true, data: data, error: nil }
    end

    def failure_result(error_message)
      { success: false, data: nil, error: error_message }
    end
  end
end