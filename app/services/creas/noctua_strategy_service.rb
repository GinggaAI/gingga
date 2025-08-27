module Creas
  class NoctuaStrategyService
    def initialize(user:, brief:, brand:, month:)
      @user, @brief, @brand, @month = user, brief, brand, month
    end

    def call
      # Create strategy plan record immediately with pending status
      strategy_plan = CreasStrategyPlan.create!(
        user: @user,
        brand: @brand,
        month: @month,
        status: :pending,
        brand_snapshot: brand_snapshot(@brand)
      )

      # Queue background job for AI processing
      GenerateNoctuaStrategyJob.perform_later(strategy_plan.id, @brief)

      # Return the plan immediately (status: pending)
      strategy_plan
    end

    private

    def brand_snapshot(brand)
      brand.slice(:name, :slug, :industry, :voice, :content_language, :account_language, :subtitle_languages, :dub_languages, :region, :timezone, :guardrails, :resources)
           .merge(
             audiences: brand.audiences.map { |a| a.slice(:demographic_profile, :interests, :digital_behavior) },
             products:  brand.products.map { |p| p.slice(:name, :description) },
             channels:  brand.brand_channels.map { |c| { platform: c.platform, handle: c.handle, priority: c.priority } }
           )
    end
  end
end
