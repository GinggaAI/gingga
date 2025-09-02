class GenerateNoctuaStrategyBatchJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(strategy_plan_id, brief, batch_number, total_batches, batch_id)
    strategy_plan = CreasStrategyPlan.find(strategy_plan_id)

    Rails.logger.info "GenerateNoctuaStrategyBatchJob: Starting batch #{batch_number}/#{total_batches} for strategy plan #{strategy_plan.id} (batch_id: #{batch_id})"

    begin
      # Mark strategy plan as processing if it's the first batch
      if batch_number == 1 && strategy_plan.status == "pending"
        strategy_plan.update!(status: :processing)
        Rails.logger.info "GenerateNoctuaStrategyBatchJob: Strategy plan #{strategy_plan.id} marked as processing"
      end

      # Generate AI strategy for this specific week/batch
      system_prompt = build_batch_system_prompt(batch_number, total_batches)
      user_prompt = build_batch_user_prompt(brief, batch_number, total_batches, strategy_plan)

      Rails.logger.info "GenerateNoctuaStrategyBatchJob: Calling OpenAI for batch #{batch_number} (model: #{Rails.application.config.openai_model}, temperature: 0.4)"

      json = GinggaOpenAI::ChatClient.new(
        user: strategy_plan.user,
        model: Rails.application.config.openai_model,
        temperature: 0.4
      ).chat!(system: system_prompt, user: user_prompt)

      Rails.logger.info "GenerateNoctuaStrategyBatchJob: OpenAI response received for batch #{batch_number} (#{json&.length || 0} characters)"

      # Save raw AI response for debugging
      ai_response = AiResponse.create!(
        user: strategy_plan.user,
        service_name: "noctua",
        ai_model: Rails.application.config.openai_model,
        prompt_version: "noctua-batch-v1",
        batch_number: batch_number,
        total_batches: total_batches,
        batch_id: batch_id,
        raw_request: {
          system: system_prompt,
          user: user_prompt,
          temperature: 0.4
        },
        raw_response: json,
        metadata: {
          strategy_plan_id: strategy_plan.id,
          brief: brief,
          batch_number: batch_number,
          total_batches: total_batches,
          batch_id: batch_id
        }
      )

      parsed = JSON.parse(json)

      # Check if the response contains an error indicating incomplete brief
      if parsed.is_a?(Hash) && parsed["error"]&.include?("Incomplete brief")
        handle_incomplete_brief_error(strategy_plan, parsed["error"], batch_number)
        return
      end

      # Process and store batch results
      process_batch_results(strategy_plan, parsed, batch_number, total_batches, batch_id)

      # Check if this was the last batch
      if batch_number == total_batches
        finalize_strategy_plan(strategy_plan, batch_id)
      else
        # Queue next batch
        queue_next_batch(strategy_plan_id, brief, batch_number + 1, total_batches, batch_id)
      end

    rescue JSON::ParserError => e
      Rails.logger.error "GenerateNoctuaStrategyBatchJob: JSON parsing error for batch #{batch_number}: #{e.message}"
      handle_batch_error(strategy_plan, "Batch #{batch_number} returned non-JSON content: #{e.message}", batch_number)
    rescue StandardError => e
      Rails.logger.error "GenerateNoctuaStrategyBatchJob: Unexpected error for batch #{batch_number}: #{e.message}"
      Rails.logger.error "GenerateNoctuaStrategyBatchJob: Error backtrace: #{e.backtrace.join("\n")}" if e.backtrace
      handle_batch_error(strategy_plan, "Batch #{batch_number} failed: #{e.message}", batch_number)
    end
  end

  private

  def build_batch_system_prompt(batch_number, total_batches)
    base_prompt = Creas::Prompts.noctua_system

    batch_context = "\n\nIMPORTANT BATCH CONTEXT:\n"
    batch_context += "- You are generating content for WEEK #{batch_number} of a #{total_batches}-week strategy\n"
    batch_context += "- Focus ONLY on week #{batch_number} content ideas (maximum 7 content items)\n"
    batch_context += "- This is part of a larger monthly strategy that will be assembled from #{total_batches} weekly batches\n"
    batch_context += "- Ensure content variety and uniqueness for this specific week\n"
    batch_context += "- Return ONLY the weekly_plan array for week #{batch_number}, with exactly the format expected\n"

    base_prompt + batch_context
  end

  def build_batch_user_prompt(brief, batch_number, total_batches, strategy_plan)
    base_prompt = Creas::Prompts.noctua_user(brief)

    # Add context from previous batches to avoid repetition
    existing_content = get_existing_content_context(strategy_plan, batch_number)

    batch_context = "\n\nWEEK #{batch_number} SPECIFIC REQUIREMENTS:\n"
    batch_context += "- Generate content ideas ONLY for week #{batch_number}\n"
    batch_context += "- Maximum 7 content items for this week\n"
    batch_context += "- Week numbering: this is week #{batch_number} of #{total_batches}\n"

    if existing_content.present?
      batch_context += "\nEXISTING CONTENT FROM PREVIOUS WEEKS (avoid duplication):\n"
      batch_context += existing_content
    end

    batch_context += "\n\nReturn the response in this exact format:\n"
    batch_context += "{\n"
    batch_context += "  \"week\": #{batch_number},\n"
    batch_context += "  \"ideas\": [\n"
    batch_context += "    { /* content item 1 */ },\n"
    batch_context += "    { /* content item 2 */ },\n"
    batch_context += "    // ... up to 7 items maximum\n"
    batch_context += "  ]\n"
    batch_context += "}\n"

    base_prompt + batch_context
  end

  def get_existing_content_context(strategy_plan, current_batch_number)
    # Get existing content from previous batches to provide context
    existing_items = strategy_plan.creas_content_items.where("batch_number < ?", current_batch_number)

    return "" if existing_items.empty?

    context = existing_items.map do |item|
      "- Week #{item.batch_number}: #{item.pilar} - #{item.content_name} (#{item.platform})"
    end.join("\n")

    context.length > 1000 ? context.first(1000) + "..." : context
  end

  def process_batch_results(strategy_plan, parsed_response, batch_number, total_batches, batch_id)
    Rails.logger.info "GenerateNoctuaStrategyBatchJob: Processing batch #{batch_number} results"

    # If this is the first batch and the response contains strategy-level information,
    # extract and store it for finalization (backwards compatibility with full strategy responses)
    if batch_number == 1 && parsed_response.is_a?(Hash) && (parsed_response["strategy_name"] || parsed_response["objective_of_the_month"])
      Rails.logger.info "GenerateNoctuaStrategyBatchJob: First batch contains strategy-level information, storing for finalization"
      strategy_info = {
        strategy_name: parsed_response["strategy_name"],
        objective_of_the_month: parsed_response["objective_of_the_month"],
        monthly_themes: parsed_response["monthly_themes"],
        content_distribution: parsed_response["content_distribution"],
        remix_duet_plan: parsed_response["remix_duet_plan"],
        publish_windows_local: parsed_response["publish_windows_local"]
      }.compact

      # Store strategy-level info in meta for later use during finalization
      current_meta = strategy_plan.meta || {}
      current_meta["strategy_info_from_ai"] = strategy_info
      strategy_plan.update!(meta: current_meta)
    end

    # For Noctua batches, we expect a simpler format focused on this week only
    # However, for backwards compatibility, handle full strategy responses in the first batch
    if batch_number == 1 && parsed_response.is_a?(Hash) && parsed_response["weekly_plan"].present?
      # This is a full strategy response, extract the current week's data
      full_weekly_plan = parsed_response["weekly_plan"]
      current_week_data = full_weekly_plan.find { |week| week["week_number"] == batch_number || week["week"] == batch_number }
      week_data = current_week_data || {}
      ideas = week_data["content_pieces"] || week_data["ideas"] || []

      # Store the full weekly_plan structure for later use in finalization
      current_meta = strategy_plan.meta || {}
      current_meta["full_weekly_plan_from_ai"] = full_weekly_plan
      strategy_plan.update!(meta: current_meta)

      Rails.logger.info "GenerateNoctuaStrategyBatchJob: Extracted week #{batch_number} from full strategy response with #{ideas.count} ideas"
    elsif parsed_response.is_a?(Hash) && parsed_response["weekly_plan"].present?
      # For batches 2-4 when we have a full strategy response, extract the specific week
      full_weekly_plan = parsed_response["weekly_plan"]
      current_week_data = full_weekly_plan.find { |week| week["week_number"] == batch_number || week["week"] == batch_number }
      week_data = current_week_data || {}
      ideas = week_data["content_pieces"] || week_data["ideas"] || []

      Rails.logger.info "GenerateNoctuaStrategyBatchJob: Extracted week #{batch_number} from full strategy response with #{ideas.count} ideas (subsequent batch)"
    else
      # Standard batch response format
      week_data = parsed_response
      ideas = week_data["ideas"] || []
    end

    Rails.logger.info "GenerateNoctuaStrategyBatchJob: Found #{ideas.count} ideas for week #{batch_number}"

    # Store batch results in strategy plan meta for later assembly
    current_batches = strategy_plan.meta&.dig("noctua_batches") || {}
    current_batches[batch_number.to_s] = {
      batch_id: batch_id,
      week: batch_number,
      ideas: ideas,
      processed_at: Time.current,
      total_ideas: ideas.count
    }

    strategy_plan.update!(
      meta: (strategy_plan.meta || {}).merge(
        noctua_batches: current_batches,
        last_batch_processed: batch_number,
        total_batches: total_batches
      )
    )

    Rails.logger.info "GenerateNoctuaStrategyBatchJob: Batch #{batch_number} results stored in strategy plan meta"
  end

  def queue_next_batch(strategy_plan_id, brief, next_batch_number, total_batches, batch_id)
    Rails.logger.info "GenerateNoctuaStrategyBatchJob: Queuing next batch #{next_batch_number}/#{total_batches}"

    # Use perform_later with a small delay to ensure sequential processing
    # Skip delay in test environment since inline adapter doesn't support it
    if Rails.env.test?
      ::GenerateNoctuaStrategyBatchJob.perform_later(
        strategy_plan_id,
        brief,
        next_batch_number,
        total_batches,
        batch_id
      )
    else
      ::GenerateNoctuaStrategyBatchJob.set(wait: 5.seconds).perform_later(
        strategy_plan_id,
        brief,
        next_batch_number,
        total_batches,
        batch_id
      )
    end
  end

  def finalize_strategy_plan(strategy_plan, batch_id)
    Rails.logger.info "GenerateNoctuaStrategyBatchJob: Finalizing strategy plan #{strategy_plan.id} after all batches completed"

    # Use full weekly_plan from AI if available, otherwise assemble from batches
    full_weekly_plan_from_ai = strategy_plan.meta&.dig("full_weekly_plan_from_ai")

    if full_weekly_plan_from_ai.present?
      # Use the original AI response structure
      weekly_plan = full_weekly_plan_from_ai
      total_ideas = weekly_plan.sum { |week| (week["content_pieces"] || week["ideas"] || []).count }
      Rails.logger.info "GenerateNoctuaStrategyBatchJob: Using full weekly plan from AI response with #{weekly_plan.count} weeks"
    else
      # Assemble final weekly_plan from all batches
      batches = strategy_plan.meta&.dig("noctua_batches") || {}
      weekly_plan = []
      total_ideas = 0

      # Sort batches by week number and assemble
      batches.keys.sort_by(&:to_i).each do |week_num|
        batch_data = batches[week_num]
        ideas_count = (batch_data["ideas"] || []).count
        weekly_plan << {
          "week" => batch_data["week"],
          "ideas" => batch_data["ideas"] || [],
          "publish_cadence" => ideas_count
        }
        total_ideas += batch_data["total_ideas"] || 0
      end
      Rails.logger.info "GenerateNoctuaStrategyBatchJob: Assembled weekly plan from #{batches.count} batches"
    end

    # Calculate aggregated data - use existing frequency_per_week if available, otherwise calculate
    frequency_per_week = strategy_plan.frequency_per_week.present? && strategy_plan.frequency_per_week > 0 ?
                        strategy_plan.frequency_per_week :
                        (total_ideas / batches.count.to_f).round(1)

    # Use AI-generated strategy info if available, otherwise preserve existing values
    ai_strategy_info = strategy_plan.meta&.dig("strategy_info_from_ai") || {}

    objective = ai_strategy_info["objective_of_the_month"] ||
               strategy_plan.objective_of_the_month ||
               "Monthly content strategy generated in #{batches.count} weekly batches"

    strategy_name = ai_strategy_info["strategy_name"] ||
                   strategy_plan.strategy_name ||
                   "AI Generated Strategy (#{batches.count} weeks)"

    # Update strategy plan with final assembled data
    strategy_plan.update!(
      status: :completed,
      strategy_name: strategy_name,
      objective_of_the_month: objective,
      frequency_per_week: frequency_per_week,
      monthly_themes: ai_strategy_info["monthly_themes"] || strategy_plan.monthly_themes || [],
      resources_override: strategy_plan.resources_override || {},
      content_distribution: ai_strategy_info["content_distribution"] || strategy_plan.content_distribution || {},
      weekly_plan: weekly_plan,
      remix_duet_plan: ai_strategy_info["remix_duet_plan"] || strategy_plan.remix_duet_plan || {},
      publish_windows_local: ai_strategy_info["publish_windows_local"] || strategy_plan.publish_windows_local || {},
      raw_payload: {
        assembled_from_batches: batch_id,
        total_batches: batches.count,
        total_ideas: total_ideas,
        batch_details: batches,
        original_payload: strategy_plan.raw_payload
      },
      meta: (strategy_plan.meta || {}).merge(
        model: Rails.application.config.openai_model,
        prompt_version: "noctua-batch-v1",
        batch_id: batch_id,
        total_batches: batches.count,
        assembly_completed_at: Time.current
      )
    )

    Rails.logger.info "GenerateNoctuaStrategyBatchJob: Strategy plan #{strategy_plan.id} finalized with #{total_ideas} total ideas across #{batches.count} weeks"

    # Initialize content items from the weekly_plan
    initialize_content_items(strategy_plan)

    # Broadcast completion
    broadcast_completion(strategy_plan)
  end

  def initialize_content_items(strategy_plan)
    Rails.logger.info "GenerateNoctuaStrategyBatchJob: Initializing content items for strategy plan #{strategy_plan.id}"

    begin
      service = Creas::ContentItemInitializerService.new(strategy_plan: strategy_plan)
      created_items = service.call

      Rails.logger.info "GenerateNoctuaStrategyBatchJob: Successfully created #{created_items.count} content items"

      # Validate quantity guarantee
      expected_count = strategy_plan.weekly_plan.sum { |week| week["ideas"]&.count || 0 }
      actual_count = created_items.count

      if actual_count < expected_count
        Rails.logger.warn "GenerateNoctuaStrategyBatchJob: Expected #{expected_count} content items but only #{actual_count} were created"
      else
        Rails.logger.info "GenerateNoctuaStrategyBatchJob: Content creation successful: #{actual_count}/#{expected_count} items created"
      end

    rescue StandardError => e
      Rails.logger.error "GenerateNoctuaStrategyBatchJob: Failed to initialize content items: #{e.message}"
      Rails.logger.error "GenerateNoctuaStrategyBatchJob: Error backtrace: #{e.backtrace.first(5).join("\n")}" if e.backtrace
    end
  end

  def broadcast_completion(strategy_plan)
    Rails.logger.info "Strategy plan #{strategy_plan.id} completed successfully with batch processing"
  end

  def handle_batch_error(strategy_plan, error_message, batch_number)
    Rails.logger.error "GenerateNoctuaStrategyBatchJob: Handling error for batch #{batch_number}: #{error_message}"

    strategy_plan.update!(
      status: :failed,
      error_message: "Batch #{batch_number} failed: #{error_message}",
      meta: (strategy_plan.meta || {}).merge(
        failed_batch: batch_number,
        batch_error: error_message,
        failed_at: Time.current
      )
    )
  end

  def handle_incomplete_brief_error(strategy_plan, error_message, batch_number)
    Rails.logger.error "GenerateNoctuaStrategyBatchJob: Incomplete brief error for batch #{batch_number}: #{error_message}"

    strategy_plan.update!(
      status: :failed,
      error_message: "Batch #{batch_number} failed due to incomplete brief: #{error_message}",
      meta: (strategy_plan.meta || {}).merge(
        error_type: "incomplete_brief",
        failed_batch: batch_number,
        failed_at: Time.current
      )
    )
  end
end
