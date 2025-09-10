class GenerateVoxaContentJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(strategy_plan_id)
    strategy_plan = CreasStrategyPlan.find(strategy_plan_id)

    strategy_plan.update!(status: :processing)

    begin
      # Ensure initial content items exist using ContentItemInitializerService
      ensure_draft_content_exists(strategy_plan)

      # Get expected content count for validation
      expected_count = calculate_expected_content_count(strategy_plan)

      # Generate Voxa refinements
      strategy_plan_data = Creas::StrategyPlanFormatter.new(strategy_plan).for_voxa
      brand_context = build_brand_context(strategy_plan.brand)

      system_msg = Creas::Prompts.voxa_system(strategy_plan_data: strategy_plan_data)
      user_msg = Creas::Prompts.voxa_user(strategy_plan_data: strategy_plan_data, brand_context: brand_context)

      # Call OpenAI
      client = GinggaOpenAI::ChatClient.new(
        user: strategy_plan.user,
        model: Rails.application.config.openai_model,
        temperature: 0.4
      )
      response = client.chat!(system: system_msg, user: user_msg)

      # Save raw AI response for debugging
      AiResponse.create!(
        user: strategy_plan.user,
        service_name: "voxa",
        ai_model: Rails.application.config.openai_model,
        prompt_version: "voxa-2025-08-28",
        raw_request: {
          system: system_msg,
          user: user_msg,
          temperature: 0.5
        },
        raw_response: response,
        metadata: {
          strategy_plan_id: strategy_plan.id,
          brand_id: strategy_plan.brand&.id,
          expected_content_count: expected_count
        }
      )

      parsed_response = JSON.parse(response)
      voxa_items = parsed_response.fetch("items")

      # Process Voxa items and ensure we have the right count
      processed_count = process_voxa_items(strategy_plan, voxa_items, expected_count)

      # Update strategy plan status
      strategy_plan.update!(
        status: :completed,
        meta: (strategy_plan.meta || {}).merge(
          voxa_processed_at: Time.current,
          voxa_items_count: processed_count,
          expected_content_count: expected_count
        )
      )

      # Log successful completion

    rescue JSON::ParserError => e
      Rails.logger.error "Voxa GenerateVoxaContentJob: JSON parsing error for strategy plan #{strategy_plan.id}: #{e.message}"
      handle_error(strategy_plan, "Voxa returned non-JSON content: #{e.message}")
    rescue KeyError => e
      Rails.logger.error "Voxa GenerateVoxaContentJob: Missing key in Voxa response for strategy plan #{strategy_plan.id}: #{e.message}"
      handle_error(strategy_plan, "Voxa response missing expected key: #{e.message}")
    rescue StandardError => e
      Rails.logger.error "Voxa GenerateVoxaContentJob: Unexpected error for strategy plan #{strategy_plan.id}: #{e.message}"
      Rails.logger.error "Voxa GenerateVoxaContentJob: Error backtrace: #{e.backtrace.join("\n")}" if e.backtrace
      handle_error(strategy_plan, e.message)
    end
  end

  private

  def ensure_draft_content_exists(strategy_plan)
    # Use ContentItemInitializerService to ensure draft content exists
    existing_count = strategy_plan.creas_content_items.count

    if existing_count == 0
      Creas::ContentItemInitializerService.new(strategy_plan: strategy_plan).call
      new_count = strategy_plan.creas_content_items.count
    else
    end
  end

  def calculate_expected_content_count(strategy_plan)
    # Use the same logic as ContentItemInitializerService to calculate expected count
    strategy_plan.weekly_plan.sum { |week| week["ideas"]&.count || 0 }
  end

  def process_voxa_items(strategy_plan, voxa_items, expected_count)
    processed_items = []

    CreasContentItem.transaction do
      voxa_items.each_with_index do |item, index|
        Rails.logger.debug "Voxa GenerateVoxaContentJob: Processing item #{index + 1}/#{voxa_items.count}: #{item['id']}"
        processed_item = upsert_voxa_item(strategy_plan, item)
        processed_items << processed_item if processed_item&.persisted?
      end
    end

    actual_count = processed_items.count

    # Validate count matches expectation
    if actual_count != expected_count
      Rails.logger.warn "Voxa GenerateVoxaContentJob: Voxa processing count mismatch for strategy plan #{strategy_plan.id}: expected #{expected_count}, got #{actual_count}"

      # Attempt to ensure we have the right number of content items
      ensure_complete_content_set(strategy_plan, expected_count, actual_count)
    else
    end

    # Return final count
    final_count = strategy_plan.creas_content_items.count
    final_count
  end

  def upsert_voxa_item(strategy_plan, item)
    attrs = map_voxa_item_to_attrs(item)
    origin_id = item["origin_id"]

    # Find existing record by various methods
    rec = find_existing_content_item(strategy_plan, origin_id, attrs[:content_id])

    if rec&.persisted?
      # Update existing record with Voxa refinements
      update_existing_item(rec, attrs, item)
    else
      # This should rarely happen if ContentItemInitializerService did its job
      Rails.logger.warn "Creating new content item for origin_id: #{origin_id}"
      rec = create_new_item(strategy_plan, attrs)
    end

    rec
  end

  def find_existing_content_item(strategy_plan, origin_id, content_id)
    # Try multiple matching strategies
    return strategy_plan.creas_content_items.find_by(content_id: origin_id) if origin_id.present?
    return strategy_plan.creas_content_items.find_by(origin_id: origin_id) if origin_id.present?
    return strategy_plan.creas_content_items.find_by(content_id: content_id) if content_id.present?
    nil
  end

  def update_existing_item(rec, attrs, voxa_item)
    # Preserve critical existing data
    preserved_attrs = {
      content_id: rec.content_id,        # Keep original content_id
      origin_id: rec.origin_id,          # Keep original origin_id
      day_of_the_week: rec.day_of_the_week, # Preserve day assignment
      week: rec.week,                    # Preserve week assignment
      pilar: rec.pilar                   # Preserve pilar
    }

    # Merge Voxa refinements with preserved data
    final_attrs = attrs.merge(preserved_attrs)
    final_attrs[:status] = "in_production" # Mark as processed by Voxa

    # Ensure shot plan is properly set
    final_attrs[:shotplan] = ensure_shot_plan(voxa_item, rec)

    rec.assign_attributes(final_attrs)
    rec.save!
    rec
  end

  def create_new_item(strategy_plan, attrs)
    rec = CreasContentItem.new(attrs)
    rec.user = strategy_plan.user
    rec.brand = strategy_plan.brand
    rec.creas_strategy_plan = strategy_plan
    rec.save!
    rec
  end

  def ensure_shot_plan(voxa_item, existing_record)
    # Priority order for shot plan:
    # 1. Voxa provided shot plan
    # 2. Existing shot plan from record
    # 3. Default shot plan based on template

    voxa_shotplan = voxa_item["shotplan"]
    existing_shotplan = existing_record&.shotplan

    if voxa_shotplan.present? && voxa_shotplan.is_a?(Hash) &&
       (voxa_shotplan["scenes"].present? || voxa_shotplan["beats"].present?)
      # Accept shotplan if it has scenes (for most templates) OR beats (for narration_over_7_images)
      voxa_shotplan
    elsif existing_shotplan.present? && existing_shotplan.is_a?(Hash)
      existing_shotplan
    else
      # Generate default shot plan
      generate_default_shotplan(voxa_item)
    end
  end

  def generate_default_shotplan(item)
    template = item["template"] || "only_avatars"

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
      # Default for only_avatars, avatar_and_video, etc.
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

  def ensure_complete_content_set(strategy_plan, expected_count, actual_count)
    # If we're missing content items, ensure the ContentItemInitializerService
    # quantity guarantee kicks in
    if actual_count < expected_count
      missing_count = expected_count - actual_count
      Creas::ContentItemInitializerService.new(strategy_plan: strategy_plan).call

      # Log the result
      final_count = strategy_plan.creas_content_items.count
    end
  end

  def map_voxa_item_to_attrs(item)
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
      shotplan: {}, # Will be set by ensure_shot_plan
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

  def normalize_platform(platform)
    # Normalize platform names to match database conventions
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
    # Same logic as VoxaContentService
    days_of_week = %w[Monday Tuesday Wednesday Thursday Friday Saturday Sunday]

    # 1. Check if Voxa specifies a day directly
    day_from_voxa = item["day_of_the_week"] || item.dig("meta", "day_of_the_week")
    return day_from_voxa if day_from_voxa.in?(days_of_week)

    # 2. Check scheduled_day field
    scheduled_day = item.dig("meta", "scheduled_day") || item["scheduled_day"]
    return scheduled_day if scheduled_day.in?(days_of_week)

    # 3. Try to extract from publish_date if available
    publish_date = item["publish_date"]
    if publish_date.present?
      begin
        date = Date.parse(publish_date)
        return date.strftime("%A")
      rescue Date::Error => e
        Rails.logger.warn "GenerateVoxaContentJob: Failed to parse publish_date '#{publish_date}': #{e.message}"
        # Fall through to pilar-based assignment
      end
    end

    # 4. Default: Use strategic distribution based on content pilar
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
    Rails.logger.warn "GenerateVoxaContentJob: Failed to parse date '#{date_string}': #{e.message}"
    nil
  end

  def parse_datetime(datetime_string)
    return nil if datetime_string.blank?
    Time.zone.parse(datetime_string)
  rescue ArgumentError => e
    Rails.logger.warn "GenerateVoxaContentJob: Failed to parse datetime '#{datetime_string}': #{e.message}"
    nil
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

  def handle_error(strategy_plan, error_message)
    Rails.logger.error "Voxa GenerateVoxaContentJob: Handling error for strategy plan #{strategy_plan.id}: #{error_message}"

    strategy_plan.update!(
      status: :failed,
      error_message: error_message,
      meta: (strategy_plan.meta || {}).merge(
        voxa_failed_at: Time.current,
        voxa_error: error_message
      )
    )

    Rails.logger.error "Voxa GenerateVoxaContentJob: Strategy plan #{strategy_plan.id} marked as failed with error: #{error_message}"
    Rails.logger.error "Voxa GenerateVoxaContentJob: Error metadata saved to strategy plan meta field"
  end

  def normalize_template(template)
    # Valid templates according to CreasContentItem model validation
    valid_templates = %w[only_avatars avatar_and_video narration_over_7_images remix one_to_three_videos]

    return "only_avatars" if template.blank?

    # If template is already valid, return it
    return template if valid_templates.include?(template)

    # Template normalization mapping for common variations
    template_mappings = {
      "solo_avatar" => "only_avatars",
      "single_avatar" => "only_avatars",
      "avatar_only" => "only_avatars",
      "text" => "only_avatars",
      "avatar" => "only_avatars",
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

    # Try to normalize the template
    normalized_template = template_mappings[template.downcase.strip]
    if normalized_template
      return normalized_template
    end

    # If no mapping found, log the unknown template and default to only_avatars
    Rails.logger.warn "Voxa GenerateVoxaContentJob: Unknown template '#{template}', defaulting to 'only_avatars'"
    "only_avatars"
  end
end
