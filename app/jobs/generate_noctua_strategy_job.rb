class GenerateNoctuaStrategyJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(strategy_plan_id, brief)
    strategy_plan = CreasStrategyPlan.find(strategy_plan_id)
    strategy_plan.update!(status: :processing)

    begin
      # Generate AI strategy using the original service logic
      system_prompt = Creas::Prompts.noctua_system
      user_prompt   = Creas::Prompts.noctua_user(brief)

      json = GinggaOpenAI::ChatClient.new(
        user: strategy_plan.user,
        model: "gpt-4o",
        temperature: 0.4
      ).chat!(system: system_prompt, user: user_prompt)

      # Save raw AI response for debugging
      AiResponse.create!(
        user: strategy_plan.user,
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
          strategy_plan_id: strategy_plan.id,
          brief: brief
        }
      )

      parsed = JSON.parse(json)

      # Validate and potentially fix weekly distribution
      validated_payload = Creas::WeeklyDistributionValidator.validate_weekly_distribution!(parsed)

      # Update the strategy plan with AI response
      strategy_plan.update!(
        status: :completed,
        strategy_name: parsed["strategy_name"],
        objective_of_the_month: parsed.fetch("objective_of_the_month"),
        frequency_per_week: parsed.fetch("frequency_per_week"),
        monthly_themes: parsed["monthly_themes"] || [],
        resources_override: parsed["resources_override"] || {},
        content_distribution: parsed["content_distribution"] || {},
        weekly_plan: parsed["weekly_plan"] || [],
        remix_duet_plan: parsed["remix_duet_plan"] || {},
        publish_windows_local: parsed["publish_windows_local"] || {},
        raw_payload: parsed,
        meta: { model: "gpt-4o", prompt_version: "noctua-v1" }
      )

      # Broadcast completion via Turbo Stream
      broadcast_completion(strategy_plan)

    rescue JSON::ParserError => e
      handle_error(strategy_plan, "Model returned non-JSON content: #{e.message}")
    rescue StandardError => e
      handle_error(strategy_plan, e.message)
    end
  end

  private

  def broadcast_completion(strategy_plan)
    # For now, we'll implement a simple approach without Turbo Streams
    # Could be enhanced later with ActionCable/Turbo Streams for real-time updates
    Rails.logger.info "Strategy plan #{strategy_plan.id} completed successfully"
  end

  def handle_error(strategy_plan, error_message)
    strategy_plan.update!(
      status: :failed,
      error_message: error_message
    )

    Rails.logger.error "Strategy plan #{strategy_plan.id} failed: #{error_message}"
  end
end
