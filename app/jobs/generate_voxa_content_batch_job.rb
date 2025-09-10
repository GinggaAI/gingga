class GenerateVoxaContentBatchJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(strategy_plan_id, batch_number, total_batches, batch_id)
    strategy_plan = CreasStrategyPlan.find(strategy_plan_id)

    begin
      # Mark strategy plan as processing if it's the first batch
      if batch_number == 1 && strategy_plan.status == "pending"
        strategy_plan.update!(status: :processing)
      end

      # Ensure initial content items exist using ContentItemInitializerService
      ensure_draft_content_exists(strategy_plan)

      # Get content items for this batch (max 7 items)
      content_items = get_content_items_for_batch(strategy_plan, batch_number, total_batches)

      if content_items.empty?
        Rails.logger.warn "Voxa GenerateVoxaContentBatchJob: No content items found for week #{batch_number}, completing batch"
        mark_batch_completed(strategy_plan, batch_number, total_batches, batch_id, 0)
        return
      end

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

      system_msg = build_batch_system_prompt(strategy_plan_data, batch_number, total_batches)
      user_msg = build_batch_user_prompt(strategy_plan_data, brand_context, existing_content_context, batch_number)

      # Call OpenAI
      client = GinggaOpenAI::ChatClient.new(
        user: strategy_plan.user,
        model: Rails.application.config.openai_model,
        temperature: 0.5
      )
      response = client.chat!(system: system_msg, user: user_msg)

      # Save raw AI response for debugging
      AiResponse.create!(
        user: strategy_plan.user,
        service_name: "voxa",
        ai_model: Rails.application.config.openai_model,
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

      parsed_response = JSON.parse(response)
      voxa_items = parsed_response.fetch("items")

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
      Rails.logger.error "Voxa GenerateVoxaContentBatchJob: JSON parsing error for batch #{batch_number}: #{e.message}"
      handle_batch_error(strategy_plan, "Batch #{batch_number} returned non-JSON content: #{e.message}", batch_number, content_items)
    rescue KeyError => e
      Rails.logger.error "Voxa GenerateVoxaContentBatchJob: Missing key in Voxa batch #{batch_number} response: #{e.message}"
      handle_batch_error(strategy_plan, "Voxa batch #{batch_number} response missing expected key: #{e.message}", batch_number, content_items)
    rescue StandardError => e
      Rails.logger.error "Voxa GenerateVoxaContentBatchJob: Unexpected error for batch #{batch_number}: #{e.message}"
      Rails.logger.error "Voxa GenerateVoxaContentBatchJob: Error backtrace: #{e.backtrace.join("\n")}" if e.backtrace
      handle_batch_error(strategy_plan, "Batch #{batch_number} failed: #{e.message}", batch_number, content_items)
    end
  end

  private

  def ensure_draft_content_exists(strategy_plan)
    existing_count = strategy_plan.creas_content_items.count

    if existing_count == 0
      Creas::ContentItemInitializerService.new(strategy_plan: strategy_plan).call
      new_count = strategy_plan.creas_content_items.count
    else
    end
  end

  def get_content_items_for_batch(strategy_plan, batch_number, total_batches)
    # Organize content items by week - each batch processes content from one specific week
    # batch_number corresponds to the week number (1-4)


    # Get all available content items for the specific week that haven't been processed
    available_items = strategy_plan.creas_content_items.where(
      status: [ "draft", "in_progress" ],
      batch_number: [ nil, batch_number ],
      week: batch_number
    ).order(:created_at)


    available_items
  end

  def build_batch_system_prompt(strategy_plan_data, batch_number, total_batches)
    base_prompt = Creas::Prompts.voxa_system(strategy_plan_data: strategy_plan_data)

    batch_context = %{

IMPORTANT BATCH CONTEXT:

- You are processing WEEK #{batch_number} content items (batch #{batch_number} of #{total_batches})
- This batch contains all content items scheduled for week #{batch_number}
- Focus on high-quality refinement of ONLY the provided week #{batch_number} content items
- Ensure each item is unique and follows the brand guidelines for this week
- Return ALL items that were provided in the input, refined and enhanced
- Maintain thematic consistency within week #{batch_number} while ensuring variety
}

    base_prompt + batch_context
  end

  def build_batch_user_prompt(strategy_plan_data, brand_context, existing_content_context, batch_number)
    base_prompt = Creas::Prompts.voxa_user(strategy_plan_data: strategy_plan_data, brand_context: brand_context)

    batch_context = %(

WEEK #{batch_number} BATCH INSTRUCTIONS:

- Refine and enhance ONLY the week #{batch_number} content items provided in this batch
- Ensure content variety within the week while maintaining weekly thematic coherence
- Each item must be production-ready with complete details for week #{batch_number}
- Consider the weekly narrative flow and content progression
)

    if existing_content_context.present?
      batch_context += %{
EXISTING CONTENT FROM PREVIOUS BATCHES (avoid duplication):
#{existing_content_context}
}
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
    skipped_count = 0


    voxa_items.each_with_index do |item, index|
      begin
        processed_item = upsert_voxa_batch_item(strategy_plan, item, content_items, batch_number)
        if processed_item&.persisted?
          processed_items << processed_item
        else
          skipped_count += 1
          Rails.logger.warn "Voxa GenerateVoxaContentBatchJob: Skipped processing item #{item['id']} in batch #{batch_number} (item #{index + 1}/#{voxa_items.count})"
        end
      rescue => e
        skipped_count += 1
        Rails.logger.error "Voxa GenerateVoxaContentBatchJob: Error processing item #{item['id']} in batch #{batch_number}: #{e.message}"
        Rails.logger.error "Voxa GenerateVoxaContentBatchJob: Continuing with next item..."
        # Continue processing other items
      end
    end

    actual_count = processed_items.count

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
      Rails.logger.warn "Voxa GenerateVoxaContentBatchJob: Creating new content item for batch #{batch_number}, origin_id: #{origin_id}"
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
    rescue ActiveRecord::RecordInvalid => e
      # Handle content name uniqueness validation errors gracefully
      if e.record.errors[:content_name].any? { |msg| msg.include?("already exists for this brand") }
        Rails.logger.warn "Voxa GenerateVoxaContentBatchJob: Content name uniqueness error for item #{rec.content_id} in batch #{batch_number}: #{e.message}"
        Rails.logger.warn "Voxa GenerateVoxaContentBatchJob: Attempting to resolve by generating unique content name"

        # Generate a unique content name by appending a suffix
        original_name = attrs[:content_name]
        unique_name = generate_unique_content_name(original_name, rec.brand_id)

        # Retry with unique name
        final_attrs[:content_name] = unique_name
        rec.assign_attributes(final_attrs)

        begin
          rec.save!
        rescue ActiveRecord::RecordInvalid => retry_error
          Rails.logger.error "Voxa GenerateVoxaContentBatchJob: Failed to update content item #{rec.content_id} even with unique name in batch #{batch_number}: #{retry_error.message}"
          Rails.logger.error "Voxa GenerateVoxaContentBatchJob: Continuing processing - item #{rec.content_id} will remain in status #{original_status}"
          # Don't re-raise - continue processing other items
          return rec
        end
      else
        Rails.logger.error "Voxa GenerateVoxaContentBatchJob: Failed to update content item #{rec.content_id} in batch #{batch_number}: #{e.message}"
        Rails.logger.error "Voxa GenerateVoxaContentBatchJob: Continuing processing - item #{rec.content_id} will remain in status #{original_status}"
        # Don't re-raise - continue processing other items
        return rec
      end
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

    begin
      rec.save!
    rescue ActiveRecord::RecordInvalid => e
      # Handle content name uniqueness validation errors gracefully
      if e.record.errors[:content_name].any? { |msg| msg.include?("already exists for this brand") }
        Rails.logger.warn "Voxa GenerateVoxaContentBatchJob: Content name uniqueness error for new item in batch #{batch_number}: #{e.message}"
        Rails.logger.warn "Voxa GenerateVoxaContentBatchJob: Attempting to resolve by generating unique content name"

        # Generate a unique content name by appending a suffix
        original_name = attrs[:content_name]
        unique_name = generate_unique_content_name(original_name, strategy_plan.brand_id)

        # Retry with unique name
        rec.content_name = unique_name

        begin
          rec.save!
        rescue ActiveRecord::RecordInvalid => retry_error
          Rails.logger.error "Voxa GenerateVoxaContentBatchJob: Failed to create content item even with unique name in batch #{batch_number}: #{retry_error.message}"
          Rails.logger.error "Voxa GenerateVoxaContentBatchJob: Continuing processing - item creation failed"
          # Don't re-raise - continue processing other items
          return nil
        end
      else
        Rails.logger.error "Voxa GenerateVoxaContentBatchJob: Failed to create content item in batch #{batch_number}: #{e.message}"
        Rails.logger.error "Voxa GenerateVoxaContentBatchJob: Continuing processing - item creation failed"
        # Don't re-raise - continue processing other items
        return nil
      end
    end

    rec
  end

  def ensure_shot_plan(voxa_item, existing_record)
    voxa_shotplan = voxa_item["shotplan"]
    existing_shotplan = existing_record&.shotplan

    if voxa_shotplan.present? && voxa_shotplan.is_a?(Hash) &&
       (voxa_shotplan["scenes"].present? || voxa_shotplan["beats"].present?)
      # Accept shotplan if it has scenes (for most templates) OR beats (for narration_over_7_images)
      voxa_shotplan
    elsif existing_shotplan.present? && existing_shotplan.is_a?(Hash)
      existing_shotplan
    else
      generate_default_shotplan(voxa_item)
    end
  end

  def generate_default_shotplan(item)
    template = item["template"] || "solo_avatars"

    case template
    when "narration_over_7_images"
      {
        "scenes" => [],
        "beats" => (1..7).map do |idx|
          {
            "idx" => idx,
            "image_prompt" => "Image #{idx}: #{item['title'] || 'Content image'} related visual",
            "voiceover" => "Voiceover for image #{idx} - #{item['description'] || 'content description'}"
          }
        end
      }
    else
      # Default for solo_avatars, avatar_and_video, etc.
      {
        "scenes" => [
          {
            "id" => 1,
            "role" => "Hook",
            "type" => "avatar",
            "visual" => "Opening scene",
            "on_screen_text" => item["hook"] || "Hook text",
            "voiceover" => item["hook"] || "Hook voiceover",
            "avatar_id" => "default_avatar",
            "voice_id" => "default_voice"
          },
          {
            "id" => 2,
            "role" => "Development",
            "type" => "avatar",
            "visual" => "Main content",
            "on_screen_text" => item["description"] || "Main content",
            "voiceover" => item["description"] || "Main content voiceover",
            "avatar_id" => "default_avatar",
            "voice_id" => "default_voice"
          },
          {
            "id" => 3,
            "role" => "Close",
            "type" => "avatar",
            "visual" => "Call to action",
            "on_screen_text" => "CTA: Engage with this content!",
            "voiceover" => "CTA: Engage with this content!",
            "avatar_id" => "default_avatar",
            "voice_id" => "default_voice"
          }
        ],
        "beats" => []
      }
    end
  end

  def mark_batch_completed(strategy_plan, batch_number, total_batches, batch_id, processed_count)
    # Check for stuck items in this batch
    stuck_in_progress = strategy_plan.creas_content_items.where(
      status: "in_progress",
      batch_number: batch_number
    ).count

    if stuck_in_progress > 0
      Rails.logger.warn "Voxa GenerateVoxaContentBatchJob: Batch #{batch_number} has #{stuck_in_progress} items still in 'in_progress' status after completion"
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
    # Check for items stuck in in_progress status and fix them
    stuck_items = strategy_plan.creas_content_items.where(status: "in_progress")
    if stuck_items.exists?
      Rails.logger.warn "Voxa GenerateVoxaContentBatchJob: Found #{stuck_items.count} items stuck in 'in_progress' status, fixing them"
      stuck_items.update_all(status: "in_production")
    end

    # Count final processed items
    total_processed = strategy_plan.creas_content_items.where(status: "in_production").count
    total_expected = strategy_plan.creas_content_items.count
    draft_items = strategy_plan.creas_content_items.where(status: "draft").count

    # Log any remaining issues
    if draft_items > 0
      Rails.logger.warn "Voxa GenerateVoxaContentBatchJob: #{draft_items} items remain in draft status after processing"
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
  end

  def handle_batch_error(strategy_plan, error_message, batch_number, content_items = nil)
    Rails.logger.error "Voxa GenerateVoxaContentBatchJob: Handling error for batch #{batch_number}: #{error_message}"

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

    Rails.logger.error "Voxa GenerateVoxaContentBatchJob: Strategy plan #{strategy_plan.id} batch #{batch_number} marked as failed"
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
      rescue Date::Error => e
        Rails.logger.warn "Voxa GenerateVoxaContentBatchJob: Failed to parse publish_date '#{publish_date}': #{e.message}"
        # Fall through to pilar-based assignment
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
  rescue Date::Error => e
    Rails.logger.warn "Voxa GenerateVoxaContentBatchJob: Failed to parse date '#{date_string}': #{e.message}"
    nil
  end

  def parse_datetime(datetime_string)
    return nil if datetime_string.blank?
    Time.zone.parse(datetime_string)
  rescue ArgumentError => e
    Rails.logger.warn "Voxa GenerateVoxaContentBatchJob: Failed to parse datetime '#{datetime_string}': #{e.message}"
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
      return normalized_template
    end

    Rails.logger.warn "Voxa GenerateVoxaContentBatchJob: Unknown template '#{template}', defaulting to 'solo_avatars'"
    "solo_avatars"
  end

  def generate_unique_content_name(original_name, brand_id)
    return original_name if original_name.blank?

    # Start with the original name and try different suffixes until we find a unique one
    base_name = original_name.strip
    max_attempts = 10

    (1..max_attempts).each do |attempt|
      candidate_name = "#{base_name} v#{attempt}"

      # Check if this name already exists for this brand
      exists = CreasContentItem
        .where(brand_id: brand_id)
        .where(content_name: candidate_name)
        .exists?

      unless exists
        return candidate_name
      end
    end

    # If all attempts failed, use timestamp as suffix
    timestamp_suffix = Time.current.strftime("%m%d%H%M")
    fallback_name = "#{base_name} #{timestamp_suffix}"

    Rails.logger.warn "Voxa GenerateVoxaContentBatchJob: Using timestamp fallback for unique name: '#{fallback_name}'"
    fallback_name
  end
end
