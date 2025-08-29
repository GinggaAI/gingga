class GenerateVoxaContentBatchJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(strategy_plan_id, batch_number, total_batches, batch_id)
    Rails.logger.info "GenerateVoxaContentBatchJob: Starting batch #{batch_number}/#{total_batches} for strategy plan #{strategy_plan_id} (batch_id: #{batch_id})"

    strategy_plan = CreasStrategyPlan.find(strategy_plan_id)

    begin
      # Mark strategy plan as processing if it's the first batch
      if batch_number == 1 && strategy_plan.status == "pending"
        strategy_plan.update!(status: :processing)
        Rails.logger.info "GenerateVoxaContentBatchJob: Strategy plan #{strategy_plan.id} marked as processing"
      end

      # Ensure initial content items exist using ContentItemInitializerService
      ensure_draft_content_exists(strategy_plan)

      # Get content items for this batch (max 7 items)
      content_items = get_content_items_for_batch(strategy_plan, batch_number, total_batches)

      if content_items.empty?
        Rails.logger.warn "GenerateVoxaContentBatchJob: No content items found for batch #{batch_number}, completing batch"
        mark_batch_completed(strategy_plan, batch_number, total_batches, batch_id, 0)
        return
      end

      Rails.logger.info "GenerateVoxaContentBatchJob: Processing #{content_items.count} content items for batch #{batch_number}"

      # Mark items as in_progress
      content_items.update_all(
        status: "in_progress",
        batch_number: batch_number,
        batch_total: total_batches
      )

      # Generate Voxa refinements for this batch
      strategy_plan_data = Creas::StrategyPlanFormatter.new(strategy_plan).for_voxa_batch(content_items)
      brand_context = build_brand_context(strategy_plan.brand)
      existing_content_context = build_existing_content_context(strategy_plan, batch_number)

      Rails.logger.info "GenerateVoxaContentBatchJob: Building prompts for OpenAI batch #{batch_number}"
      system_msg = build_batch_system_prompt(strategy_plan_data, batch_number, total_batches)
      user_msg = build_batch_user_prompt(strategy_plan_data, brand_context, existing_content_context, batch_number)

      # Call OpenAI
      Rails.logger.info "GenerateVoxaContentBatchJob: Calling OpenAI API for batch #{batch_number} (model: gpt-4o-mini, temperature: 0.5)"
      client = GinggaOpenAI::ChatClient.new(
        user: strategy_plan.user,
        model: "gpt-4o-mini",
        temperature: 0.5
      )
      response = client.chat!(system: system_msg, user: user_msg)
      Rails.logger.info "GenerateVoxaContentBatchJob: OpenAI response received for batch #{batch_number} (#{response&.length || 0} characters)"

      # Save raw AI response for debugging
      AiResponse.create!(
        user: strategy_plan.user,
        service_name: "voxa",
        ai_model: "gpt-4o-mini",
        prompt_version: "voxa-batch-2025-08-28",
        batch_number: batch_number,
        total_batches: total_batches,
        batch_id: batch_id,
        raw_request: {
          system: system_msg,
          user: user_msg,
          temperature: 0.5
        },
        raw_response: response,
        metadata: {
          strategy_plan_id: strategy_plan.id,
          brand_id: strategy_plan.brand&.id,
          batch_number: batch_number,
          total_batches: total_batches,
          batch_id: batch_id,
          content_items_count: content_items.count
        }
      )

      Rails.logger.info "GenerateVoxaContentBatchJob: Parsing OpenAI response for batch #{batch_number}"
      parsed_response = JSON.parse(response)
      voxa_items = parsed_response.fetch("items")
      Rails.logger.info "GenerateVoxaContentBatchJob: Found #{voxa_items.count} items in Voxa batch #{batch_number} response"

      # Process Voxa items for this batch
      processed_count = process_voxa_batch_items(strategy_plan, voxa_items, content_items, batch_number)

      # Mark batch as completed and check if we're done
      mark_batch_completed(strategy_plan, batch_number, total_batches, batch_id, processed_count)

      # Check if this was the last batch
      if batch_number == total_batches
        finalize_voxa_processing(strategy_plan, batch_id)
      else
        # Queue next batch
        queue_next_batch(strategy_plan_id, batch_number + 1, total_batches, batch_id)
      end

    rescue JSON::ParserError => e
      Rails.logger.error "GenerateVoxaContentBatchJob: JSON parsing error for batch #{batch_number}: #{e.message}"
      handle_batch_error(strategy_plan, "Batch #{batch_number} returned non-JSON content: #{e.message}", batch_number, content_items)
    rescue KeyError => e
      Rails.logger.error "GenerateVoxaContentBatchJob: Missing key in Voxa batch #{batch_number} response: #{e.message}"
      handle_batch_error(strategy_plan, "Voxa batch #{batch_number} response missing expected key: #{e.message}", batch_number, content_items)
    rescue StandardError => e
      Rails.logger.error "GenerateVoxaContentBatchJob: Unexpected error for batch #{batch_number}: #{e.message}"
      Rails.logger.error "GenerateVoxaContentBatchJob: Error backtrace: #{e.backtrace.join("\n")}" if e.backtrace
      handle_batch_error(strategy_plan, "Batch #{batch_number} failed: #{e.message}", batch_number, content_items)
    end
  end

  private

  def ensure_draft_content_exists(strategy_plan)
    existing_count = strategy_plan.creas_content_items.count
    Rails.logger.info "GenerateVoxaContentBatchJob: Checking draft content - existing count: #{existing_count}"

    if existing_count == 0
      Rails.logger.info "GenerateVoxaContentBatchJob: No existing content found for strategy plan #{strategy_plan.id}, creating draft content"
      Creas::ContentItemInitializerService.new(strategy_plan: strategy_plan).call
      new_count = strategy_plan.creas_content_items.count
      Rails.logger.info "GenerateVoxaContentBatchJob: Created #{new_count} draft content items"
    else
      Rails.logger.info "GenerateVoxaContentBatchJob: Using existing #{existing_count} content items"
    end
  end

  def get_content_items_for_batch(strategy_plan, batch_number, total_batches)
    # Get all available content items that haven't been processed in previous batches
    available_items = strategy_plan.creas_content_items.where(
      status: [ "draft", "in_progress" ],
      batch_number: [ nil, batch_number ]
    ).order(:week, :created_at)

    # Calculate batch size (max 7 items per batch)
    batch_size = 7
    offset = (batch_number - 1) * batch_size

    # Get items for this specific batch
    available_items.limit(batch_size).offset(offset)
  end

  def build_batch_system_prompt(strategy_plan_data, batch_number, total_batches)
    base_prompt = Creas::Prompts.voxa_system(strategy_plan_data: strategy_plan_data)

    batch_context = "\n\nIMPORTANT BATCH CONTEXT:\n"
    batch_context += "- You are processing BATCH #{batch_number} of #{total_batches} for content refinement\n"
    batch_context += "- This batch contains a maximum of 7 content items\n"
    batch_context += "- Focus on high-quality refinement of ONLY the provided content items\n"
    batch_context += "- Ensure each item is unique and follows the brand guidelines\n"
    batch_context += "- Return ALL items that were provided in the input, refined and enhanced\n"

    base_prompt + batch_context
  end

  def build_batch_user_prompt(strategy_plan_data, brand_context, existing_content_context, batch_number)
    base_prompt = Creas::Prompts.voxa_user(strategy_plan_data: strategy_plan_data, brand_context: brand_context)

    batch_context = "\n\nBATCH #{batch_number} SPECIFIC INSTRUCTIONS:\n"
    batch_context += "- Refine and enhance ONLY the content items provided in this batch\n"
    batch_context += "- Ensure content variety and avoid repetition with existing content\n"
    batch_context += "- Each item must be production-ready with complete details\n"

    if existing_content_context.present?
      batch_context += "\nEXISTING CONTENT FROM PREVIOUS BATCHES (avoid duplication):\n"
      batch_context += existing_content_context
    end

    base_prompt + batch_context
  end

  def build_existing_content_context(strategy_plan, current_batch_number)
    # Get content from previous batches to avoid duplication
    existing_items = strategy_plan.creas_content_items.where("batch_number < ? AND batch_number IS NOT NULL", current_batch_number)

    return "" if existing_items.empty?

    context = existing_items.limit(10).map do |item|
      "- Batch #{item.batch_number}: #{item.pilar} - #{item.content_name} (#{item.platform})"
    end.join("\n")

    context.length > 800 ? context.first(800) + "..." : context
  end

  def process_voxa_batch_items(strategy_plan, voxa_items, content_items, batch_number)
    processed_items = []

    Rails.logger.info "GenerateVoxaContentBatchJob: Processing #{voxa_items.count} Voxa items for batch #{batch_number} in database transaction"
    CreasContentItem.transaction do
      voxa_items.each_with_index do |item, index|
        Rails.logger.debug "GenerateVoxaContentBatchJob: Processing batch #{batch_number} item #{index + 1}/#{voxa_items.count}: #{item['id']}"
        processed_item = upsert_voxa_batch_item(strategy_plan, item, content_items, batch_number)
        processed_items << processed_item if processed_item&.persisted?
      end
    end

    actual_count = processed_items.count
    Rails.logger.info "GenerateVoxaContentBatchJob: Successfully processed #{actual_count} Voxa items for batch #{batch_number}"

    actual_count
  end

  def upsert_voxa_batch_item(strategy_plan, item, content_items, batch_number)
    attrs = map_voxa_item_to_attrs(item)
    origin_id = item["origin_id"]

    # Find existing record within this batch's content items
    rec = find_existing_content_item_in_batch(content_items, origin_id, attrs[:content_id])

    if rec&.persisted?
      # Update existing record with Voxa refinements
      update_existing_batch_item(rec, attrs, item, batch_number)
    else
      # This should rarely happen if we're processing the correct batch items
      Rails.logger.warn "Creating new content item for batch #{batch_number}, origin_id: #{origin_id}"
      rec = create_new_batch_item(strategy_plan, attrs, batch_number)
    end

    rec
  end

  def find_existing_content_item_in_batch(content_items, origin_id, content_id)
    # Try multiple matching strategies within the batch items
    return content_items.find { |item| item.content_id == origin_id } if origin_id.present?
    return content_items.find { |item| item.origin_id == origin_id } if origin_id.present?
    return content_items.find { |item| item.content_id == content_id } if content_id.present?
    nil # Return nil if no match found - this will trigger creation of new item
  end

  def update_existing_batch_item(rec, attrs, voxa_item, batch_number)
    original_status = rec.status

    # Preserve critical existing data
    preserved_attrs = {
      content_id: rec.content_id,
      origin_id: rec.origin_id,
      day_of_the_week: rec.day_of_the_week,
      week: rec.week,
      pilar: rec.pilar,
      batch_number: batch_number,
      batch_total: rec.batch_total
    }

    # Merge Voxa refinements with preserved data
    final_attrs = attrs.merge(preserved_attrs)
    final_attrs[:status] = "in_production" # Mark as processed by Voxa
    final_attrs[:shotplan] = ensure_shot_plan(voxa_item, rec)

    rec.assign_attributes(final_attrs)

    begin
      rec.save!
      Rails.logger.debug "GenerateVoxaContentBatchJob: Updated content item #{rec.content_id} status: #{original_status} → in_production (batch #{batch_number})"
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "GenerateVoxaContentBatchJob: Failed to update content item #{rec.content_id} in batch #{batch_number}: #{e.message}"
      # Re-raise to trigger batch error handling
      raise
    end

    rec
  end

  def create_new_batch_item(strategy_plan, attrs, batch_number)
    attrs[:batch_number] = batch_number
    attrs[:status] = "in_production"

    rec = CreasContentItem.new(attrs)
    rec.user = strategy_plan.user
    rec.brand = strategy_plan.brand
    rec.creas_strategy_plan = strategy_plan
    rec.save!
    rec
  end

  def ensure_shot_plan(voxa_item, existing_record)
    voxa_shotplan = voxa_item["shotplan"]
    existing_shotplan = existing_record&.shotplan

    if voxa_shotplan.present? && voxa_shotplan.is_a?(Hash) && voxa_shotplan["scenes"].present?
      voxa_shotplan
    elsif existing_shotplan.present? && existing_shotplan.is_a?(Hash)
      existing_shotplan
    else
      generate_default_shotplan(voxa_item)
    end
  end

  def generate_default_shotplan(item)
    template = item["template"] || "solo_avatars"

    {
      "scenes" => [
        {
          "scene_number" => 1,
          "on_screen_text" => item["hook"] || "Hook text",
          "voiceover" => item["hook"] || "Hook voiceover",
          "avatar_id" => "default_avatar",
          "voice_id" => "default_voice"
        }
      ],
      "beats" => [
        {
          "beat_number" => 1,
          "description" => "Opening hook",
          "duration" => "3-5s"
        }
      ]
    }
  end

  def mark_batch_completed(strategy_plan, batch_number, total_batches, batch_id, processed_count)
    Rails.logger.info "GenerateVoxaContentBatchJob: Marking batch #{batch_number}/#{total_batches} as completed with #{processed_count} processed items"

    # Check for stuck items in this batch
    stuck_in_progress = strategy_plan.creas_content_items.where(
      status: "in_progress",
      batch_number: batch_number
    ).count

    if stuck_in_progress > 0
      Rails.logger.warn "GenerateVoxaContentBatchJob: Batch #{batch_number} has #{stuck_in_progress} items still in 'in_progress' status after completion"
    end

    # Store batch completion in strategy plan meta
    current_batches = strategy_plan.meta&.dig("voxa_batches") || {}
    current_batches[batch_number.to_s] = {
      batch_id: batch_id,
      batch_number: batch_number,
      processed_count: processed_count,
      stuck_in_progress: stuck_in_progress,
      completed_at: Time.current
    }

    strategy_plan.update!(
      meta: (strategy_plan.meta || {}).merge(
        voxa_batches: current_batches,
        last_batch_processed: batch_number,
        total_batches: total_batches
      )
    )
  end

  def queue_next_batch(strategy_plan_id, next_batch_number, total_batches, batch_id)
    Rails.logger.info "GenerateVoxaContentBatchJob: Queuing next batch #{next_batch_number}/#{total_batches}"

    # Use perform_later with a small delay to ensure sequential processing
    # Skip delay in test environment since inline adapter doesn't support it
    if Rails.env.test?
      ::GenerateVoxaContentBatchJob.perform_later(
        strategy_plan_id,
        next_batch_number,
        total_batches,
        batch_id
      )
    else
      ::GenerateVoxaContentBatchJob.set(wait: 5.seconds).perform_later(
        strategy_plan_id,
        next_batch_number,
        total_batches,
        batch_id
      )
    end
  end

  def finalize_voxa_processing(strategy_plan, batch_id)
    Rails.logger.info "GenerateVoxaContentBatchJob: Finalizing Voxa processing for strategy plan #{strategy_plan.id}"

    # Check for items stuck in in_progress status and fix them
    stuck_items = strategy_plan.creas_content_items.where(status: "in_progress")
    if stuck_items.exists?
      Rails.logger.warn "GenerateVoxaContentBatchJob: Found #{stuck_items.count} items stuck in 'in_progress' status, fixing them"
      stuck_items.update_all(status: "in_production")
    end

    # Count final processed items
    total_processed = strategy_plan.creas_content_items.where(status: "in_production").count
    total_expected = strategy_plan.creas_content_items.count
    draft_items = strategy_plan.creas_content_items.where(status: "draft").count

    # Log any remaining issues
    if draft_items > 0
      Rails.logger.warn "GenerateVoxaContentBatchJob: #{draft_items} items remain in draft status after processing"
    end

    # Update strategy plan status
    strategy_plan.update!(
      status: :completed,
      meta: (strategy_plan.meta || {}).merge(
        voxa_processed_at: Time.current,
        voxa_batch_id: batch_id,
        voxa_items_processed: total_processed,
        voxa_items_expected: total_expected,
        voxa_items_draft: draft_items,
        voxa_completion_rate: (total_processed.to_f / total_expected * 100).round(2),
        stuck_items_fixed: stuck_items.exists? ? stuck_items.count : 0
      )
    )

    Rails.logger.info "Voxa batch processing completed for strategy plan #{strategy_plan.id}: #{total_processed}/#{total_expected} items processed (#{(total_processed.to_f / total_expected * 100).round(1)}%), #{draft_items} draft items remaining"
  end

  def handle_batch_error(strategy_plan, error_message, batch_number, content_items = nil)
    Rails.logger.error "GenerateVoxaContentBatchJob: Handling error for batch #{batch_number}: #{error_message}"

    # Reset content items status if available
    if content_items&.any?
      content_items.update_all(status: "draft", batch_number: nil)
    end

    strategy_plan.update!(
      status: :failed,
      error_message: "Batch #{batch_number} failed: #{error_message}",
      meta: (strategy_plan.meta || {}).merge(
        voxa_failed_at: Time.current,
        voxa_failed_batch: batch_number,
        voxa_error: error_message
      )
    )

    Rails.logger.error "GenerateVoxaContentBatchJob: Strategy plan #{strategy_plan.id} batch #{batch_number} marked as failed"
  end

  def build_brand_context(brand)
    {
      "brand" => {
        "industry" => brand.industry,
        "value_proposition" => brand.value_proposition,
        "mission" => brand.mission,
        "voice" => brand.voice,
        "priority_platforms" => extract_priority_platforms(brand),
        "languages" => {
          "content_language" => brand.content_language,
          "account_language" => brand.content_language || "en-US"
        },
        "guardrails" => brand.guardrails || {}
      }
    }
  end

  def extract_priority_platforms(brand)
    platform_mapping = {
      "instagram" => "Instagram",
      "tiktok" => "TikTok",
      "youtube" => "YouTube",
      "linkedin" => "LinkedIn"
    }

    platforms = brand.brand_channels.pluck(:platform).map { |p| platform_mapping[p] || p.capitalize }.uniq
    platforms.any? ? platforms : [ "Instagram", "TikTok" ]
  end

  def map_voxa_item_to_attrs(item)
    # Reuse the same mapping logic from the original GenerateVoxaContentJob
    {
      content_id: item.fetch("id"),
      origin_id: item["origin_id"],
      origin_source: item["origin_source"] || "voxa_refinement",
      week: item.fetch("week"),
      week_index: item["week_index"],
      scheduled_day: item.dig("meta", "scheduled_day"),
      day_of_the_week: extract_day_of_week(item),
      publish_date: parse_date(item["publish_date"]),
      publish_datetime_local: parse_datetime(item["publish_datetime_local"]),
      timezone: item["timezone"],
      content_name: item.fetch("content_name"),
      status: item.fetch("status"),
      creation_date: parse_date(item["creation_date"]) || Date.current,
      content_type: item.fetch("content_type"),
      platform: normalize_platform(item.fetch("platform")),
      aspect_ratio: item["aspect_ratio"],
      language: item["language"],
      pilar: item.fetch("pilar"),
      template: normalize_template(item.fetch("template")),
      video_source: item.fetch("video_source"),
      post_description: item.fetch("post_description"),
      text_base: item.fetch("text_base"),
      hashtags: item.fetch("hashtags"),
      subtitles: item["subtitles"] || {},
      dubbing: item["dubbing"] || {},
      shotplan: {},
      assets: item["assets"] || {},
      accessibility: item["accessibility"] || {},
      meta: (item["meta"] || {}).merge(
        hook: item["hook"],
        cta: item["cta"],
        kpi_focus: item["kpi_focus"],
        success_criteria: item["success_criteria"],
        compliance_check: item["compliance_check"]
      )
    }
  end

  # Include helper methods from original job
  def normalize_platform(platform)
    platform_mapping = {
      "Instagram Reels" => "instagram",
      "Instagram" => "instagram",
      "TikTok" => "tiktok",
      "YouTube" => "youtube",
      "LinkedIn" => "linkedin"
    }
    platform_mapping[platform] || platform.downcase
  end

  def extract_day_of_week(item)
    days_of_week = %w[Monday Tuesday Wednesday Thursday Friday Saturday Sunday]

    day_from_voxa = item["day_of_the_week"] || item.dig("meta", "day_of_the_week")
    return day_from_voxa if day_from_voxa.in?(days_of_week)

    scheduled_day = item.dig("meta", "scheduled_day") || item["scheduled_day"]
    return scheduled_day if scheduled_day.in?(days_of_week)

    publish_date = item["publish_date"]
    if publish_date.present?
      begin
        date = Date.parse(publish_date)
        return date.strftime("%A")
      rescue Date::Error
        # Fall through
      end
    end

    pilar = item["pilar"]
    case pilar
    when "C" then [ "Tuesday", "Wednesday", "Thursday" ].sample
    when "R" then [ "Friday", "Saturday", "Sunday" ].sample
    when "E" then [ "Monday", "Friday", "Saturday" ].sample
    when "A" then [ "Monday", "Tuesday", "Wednesday" ].sample
    when "S" then [ "Tuesday", "Wednesday", "Thursday" ].sample
    else
      days_of_week.sample
    end
  end

  def parse_date(date_string)
    return nil if date_string.blank?
    Date.iso8601(date_string)
  rescue Date::Error
    nil
  end

  def parse_datetime(datetime_string)
    return nil if datetime_string.blank?
    Time.zone.parse(datetime_string)
  rescue ArgumentError
    nil
  end

  def normalize_template(template)
    valid_templates = %w[solo_avatars avatar_and_video narration_over_7_images remix one_to_three_videos]

    return "solo_avatars" if template.blank?
    return template if valid_templates.include?(template)

    template_mappings = {
      "solo_avatar" => "solo_avatars",
      "single_avatar" => "solo_avatars",
      "avatar_only" => "solo_avatars",
      "text" => "solo_avatars",
      "avatar" => "solo_avatars",
      "avatar_video" => "avatar_and_video",
      "avatar_with_video" => "avatar_and_video",
      "hybrid" => "avatar_and_video",
      "narration_7_images" => "narration_over_7_images",
      "narration_images" => "narration_over_7_images",
      "image_narration" => "narration_over_7_images",
      "slideshow" => "narration_over_7_images",
      "seven_images" => "narration_over_7_images",
      "carousel" => "narration_over_7_images",
      "remix_video" => "remix",
      "video_remix" => "remix",
      "repurpose" => "remix",
      "multi_video" => "one_to_three_videos",
      "multiple_videos" => "one_to_three_videos",
      "three_videos" => "one_to_three_videos",
      "videos" => "one_to_three_videos",
      "video_compilation" => "one_to_three_videos"
    }

    normalized_template = template_mappings[template.downcase.strip]
    if normalized_template
      Rails.logger.info "GenerateVoxaContentBatchJob: Normalized template '#{template}' to '#{normalized_template}'"
      return normalized_template
    end

    Rails.logger.warn "GenerateVoxaContentBatchJob: Unknown template '#{template}', defaulting to 'solo_avatars'"
    "solo_avatars"
  end
end
