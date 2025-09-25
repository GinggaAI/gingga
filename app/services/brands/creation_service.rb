module Brands
  class CreationService
    def initialize(user:)
      @user = user
    end

    def call
      @brand = @user.brands.build(
        name: "New Brand",
        slug: generate_unique_slug,
        industry: "other",
        voice: "professional"
      )

      if @brand.save
        success_result(brand: @brand)
      else
        failure_result(@brand.errors.full_messages.join(", "))
      end
    rescue StandardError => e
      failure_result("Failed to create brand: #{e.message}")
    end

    private

    attr_reader :user

    def generate_unique_slug
      counter = 1

      loop do
        candidate_slug = "brand-#{counter}"
        break candidate_slug unless @user.brands.exists?(slug: candidate_slug)
        counter += 1
      end
    end

    def success_result(data)
      { success: true, data: data, error: nil }
    end

    def failure_result(error_message)
      { success: false, data: nil, error: error_message }
    end
  end
end
