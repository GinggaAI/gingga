module Creas
  class NoctuaStrategyService
    def initialize(user:, brief:, brand:, month:, strategy_form: {})
      @user, @brief, @brand, @month = user, brief, brand, month
      @strategy_form = strategy_form
    end

    def call
      # Ensure we have fresh ActiveRecord instances to avoid class reloading issues
      fresh_user = @user.is_a?(User) ? User.find(@user.id) : @user
      fresh_brand = @brand.is_a?(Brand) ? Brand.find(@brand.id) : @brand

      # Create strategy plan record immediately with pending status
      strategy_plan_attrs = {
        user: fresh_user,
        brand: fresh_brand,
        month: @month,
        status: :pending,
        brand_snapshot: brand_snapshot(fresh_brand)
      }

      # Only set strategy form values if they were provided
      if @strategy_form.present? && @strategy_form.any?
        strategy_plan_attrs.merge!(
          objective_of_the_month: @strategy_form[:objective_of_the_month] || @strategy_form[:primary_objective],
          frequency_per_week: @strategy_form[:frequency_per_week],
          monthly_themes: @strategy_form[:monthly_themes] || [],
          resources_override: @strategy_form[:resources_override] || {}
        )
      end

      strategy_plan = CreasStrategyPlan.create!(strategy_plan_attrs)

      # Calculate number of weeks (batches) needed for the month
      total_batches = calculate_batches_for_month(@month)
      batch_id = SecureRandom.uuid

      Rails.logger.info "NoctuaStrategyService: Starting batch processing for strategy plan #{strategy_plan.id} with #{total_batches} batches (batch_id: #{batch_id})"

      # Queue first batch job for AI processing
      ::GenerateNoctuaStrategyBatchJob.perform_later(strategy_plan.id, @brief, 1, total_batches, batch_id)

      # Return the plan immediately (status: pending)
      strategy_plan
    end

    private

    def calculate_batches_for_month(month_string)
      # Always use 4 batches (weeks) for monthly strategies
      # This ensures consistent weekly batching regardless of actual calendar weeks
      4
    rescue
      # Fallback to 4 batches if there's any issue parsing the month
      4
    end

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
