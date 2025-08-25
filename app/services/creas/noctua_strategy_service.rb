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

    # Legacy method for backwards compatibility / testing
    def call_sync
      system_prompt = Creas::Prompts.noctua_system
      user_prompt   = Creas::Prompts.noctua_user(@brief)
      json = GinggaOpenAI::ChatClient.new(user: @user, model: "gpt-4o", temperature: 0.4)
                               .chat!(system: system_prompt, user: user_prompt)

      # Save raw AI response for debugging
      AiResponse.create!(
        user: @user,
        service_name: "noctua",
        ai_model: "gpt-4o",
        prompt_version: "noctua-v1",
        raw_request: {
          system: system_prompt,
          user: user_prompt,
          temperature: 0.4
        },
        raw_response: json,
        metadata: {
          brand_id: @brand&.id,
          month: @month,
          brief: @brief
        }
      )

      parsed = JSON.parse(json)

      # Validate and potentially fix weekly distribution
      validated_payload = Creas::WeeklyDistributionValidator.validate_weekly_distribution!(parsed)

      persist!(validated_payload)
    rescue JSON::ParserError
      raise "Model returned non-JSON content"
    end

    private

    def persist!(payload)
      plan = CreasStrategyPlan.create!(
        user: @user,
        brand: @brand,
        strategy_name: payload["strategy_name"],
        month: @month,
        objective_of_the_month: payload.fetch("objective_of_the_month"),
        frequency_per_week: payload.fetch("frequency_per_week"),
        monthly_themes: payload["monthly_themes"] || [],
        resources_override: payload["resources_override"] || {},
        content_distribution: payload["content_distribution"] || {},
        weekly_plan: payload["weekly_plan"] || [],
        remix_duet_plan: payload["remix_duet_plan"] || {},
        publish_windows_local: payload["publish_windows_local"] || {},
        brand_snapshot: brand_snapshot(@brand),
        raw_payload: payload,
        meta: { model: "gpt-4o", prompt_version: "noctua-v1" },
        status: :completed
      )
      plan
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
